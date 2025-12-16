import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/const.dart';
import '../app/string_utils.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'group_store.dart';
import 'thread_store.dart';

typedef SyncListenable = SelectedListenable<bool, bool?>;

class PostData extends ChangeNotifier {
  Post get data => _data;
  Post _data;

  SyncListenable get synced => _sync.select((e) => e == true);
  SyncListenable get syncing => _sync.select((e) => e == false);
  SyncListenable get error => _sync.select((e) => e == null);
  final _sync = ValueNotifier<bool?>(false);

  ValueListenable<PostData?> get quote => _quote;
  final _quote = ValueNotifier<PostData?>(null);

  Iterable<ValueNotifier<ImageData?>> get images => _images.values;
  Map<String, ValueNotifier<ImageData?>> _images = {};

  bool get original => _original;
  bool _original = false;

  bool get read => _read;
  bool _read = false;

  bool get folded => _folded;
  bool _folded = false;

  int get level => _level;
  int _level = 0;

  int get total => _total;
  int _total = 0;

  List<PostData> get children => _children;
  final _children = <PostData>[];

  String? _text;
  bool _visible = false;
  bool _visiblePending = false;
  Timer? _visibleTimer;

  PostData(Post post) : _data = post, _total = post.total {
    if (post.text == null) return;
    _sync.value = post.textFile == null;
    _images = {for (var id in post.files) id: ValueNotifier<ImageData?>(null)};
  }

  void syncRetry() {
    if (!error.value) return;
    _sync.value = false;
    notifyListeners();
  }

  void syncFrom(Post post) {
    _data = post;
    _images = {for (var id in post.files) id: ValueNotifier<ImageData?>(null)};
    _sync.value = post.textFile == null;
    setVisible(_visiblePending);
    notifyListeners();
  }

  void syncError() {
    _sync.value = null;
    notifyListeners();
  }

  void setText(String text) {
    _text = text;
    _sync.value = true;
    setVisible(_visiblePending);
    notifyListeners();
  }

  void setQuote(PostData post) {
    _quote.value = post;
    notifyListeners();
  }

  void setImage(String id, ImageData data) {
    if (_images[id]?.value == null) {
      _images[id]?.value = data;
    }
    notifyListeners();
  }

  void toggleOriginal() {
    _original = !_original;
    notifyListeners();
  }

  String getText() {
    final text = (_text ?? data.text ?? '');
    final strip = original ? text : text.stripAll;
    return switch (_sync.value) {
      null => syncTimeoutText,
      false => syncBodyText,
      true => (strip.isEmpty && data.files.isEmpty) ? emptyText : strip,
    };
  }

  Future<void> setVisible(bool v) async {
    _visiblePending = v;
    _visibleTimer?.cancel();
    _visibleTimer = Timer(0.5.seconds, () {
      _visible = v;
      if (_visible && synced.value) {
        _read = true;
        notifyListeners();
      }
    });
  }

  void toggleFold() {
    _folded = !_folded;
    notifyListeners();
  }

  void setLevel(int level) {
    _level = level;
    notifyListeners();
  }

  void addChildren(List<PostData> list) {
    _children.addAll(list);
    notifyListeners();
  }

  void incTotal() {
    _total++;
    notifyListeners();
  }
}

class ImageData {
  // String name;
  Uint8List data;
  Size size;
  ImageData(this.data, this.size);
}

class PostStore {
  ListListenable<PostData> get nItems => _nItems;
  final _nItems = ListNotifier<PostData>([]);
  ListListenable<PostData> get pItems => _pItems;
  final _pItems = ListNotifier<PostData>([]);

  bool get reachStart => _reachStart;
  var _reachStart = true;
  bool get reachEnd => _reachEnd;
  var _reachEnd = true;

  PostData? get selected => _selected;
  PostData? _selected;
  int get index => _index;
  int _index = 0;
  int get read => _read;
  int _read = 0;

  ValueListenable<bool> get postMode => _postMode;
  final _postMode = ValueNotifier<bool>(false);

  final _map = <String, PostData>{};

  static const _itemsPreFetch = 25;

  String? _cursorStart;
  String? _cursorEnd;

  Listenable get all => Listenable.merge(_map.values);

  Future<void> select(int index, bool postMode) async {
    _index = 0;
    _postMode.value = postMode;
    reset();

    final threads = Modular.get<ThreadStore>();
    final thread = threads.selected;
    if (thread == null) return;
    _read = threads.selected?.read.value ?? 0;

    if (!postMode && index == 0) {
      _reachEnd = false;
      return;
    }

    final cloud = Modular.get<CloudService>();
    final post = await cloud.getPost(thread.data.msgid, index);
    if (post == null) return;
    final data = _map.putIfAbsent(post.msgid, () => PostData(post));
    _index = index;
    _selected = data;

    _cursorStart = post.id;
    _reachStart = false;
    _cursorEnd = post.id;
    _reachEnd = false;
    _pItems.append([data]);
    _setupPosts([data]);

    if (postMode) {
      _cursorStart = post.ref.lastOrNull;
      _reachStart = post.ref.isEmpty;
    }
  }

  void reset() {
    _cursorStart = null;
    _reachStart = true;
    _nItems.clear();
    _cursorEnd = null;
    _reachEnd = true;
    _pItems.clear();
    _map.clear();
  }

  void refresh() {
    final threads = Modular.get<ThreadStore>();
    _read = threads.selected?.read.value ?? 0;
    _reachEnd = false;
    _cursorEnd = pItems.value.lastOrNull?.data.id;
    loadMore();
  }

  void setPostMode(bool value) {
    _postMode.value = value;
  }

  Future<void> loadMore({bool reverse = false}) async {
    if (reverse ? _reachStart || _cursorStart == null : _reachEnd) return;

    final cloud = Modular.get<CloudService>();
    final groups = Modular.get<GroupStore>();
    final threads = Modular.get<ThreadStore>();
    final group = groups.get(threads.selected?.data.group);
    if (group == null) return;

    late List<Post> items;
    if (postMode.value) {
      if (selected == null) return;
      if (reverse) {
        final end = selected!.data.ref.length - nItems.length;
        final start = max(0, end - _itemsPreFetch);
        final ref = selected!.data.ref.slice(start, end);
        items = await cloud.getPostsByMsgids(ref);
        _reachStart = nItems.length + items.length >= selected!.data.ref.length;
        _cursorStart = _reachStart ? null : items.last.id;
      } else {
        items = await cloud.getPostsByQuote(
          selected!.data.msgid,
          group.number,
          _itemsPreFetch,
          cursor: _cursorEnd,
        );
        _reachEnd = items.isEmpty || items.length < _itemsPreFetch;
        _cursorEnd = _reachEnd ? null : items.last.id;
      }
    } else {
      if (threads.selected == null) return;
      items = await cloud.getPosts(
        threads.selected!.data.msgid,
        group.number,
        _itemsPreFetch,
        cursor: reverse ? _cursorStart : _cursorEnd,
        reverse: reverse,
      );
      if (reverse) {
        _reachStart = items.isEmpty || items.length < _itemsPreFetch;
        _cursorStart = _reachStart ? null : items.first.id;
      } else {
        _reachEnd = items.isEmpty || items.length < _itemsPreFetch;
        _cursorEnd = _reachEnd ? null : items.last.id;
      }
    }

    final posts = items.map((e) => PostData(e)).toList();
    final add = posts.whereNot((e) => _map.containsKey(e.data.msgid));
    // if (!postMode.value || add.isNotEmpty) {
    _map.addAll({for (var post in add) post.data.msgid: post});
    reverse ? _nItems.append(posts.reversed) : _pItems.append(posts);
    _setupPosts(posts);
    // }
  }

  void toggleExpand(PostData post) {
    post.toggleFold();
    loadReply(post);
  }

  Future<void> loadReply(PostData post) async {
    final cloud = Modular.get<CloudService>();
    final groups = Modular.get<GroupStore>();
    final threads = Modular.get<ThreadStore>();
    final group = groups.get(threads.selected?.data.group);
    if (group == null) return;
    final items = await cloud.getPostsByQuote(
      post.data.msgid,
      group.number,
      _itemsPreFetch,
      cursor: post.children.lastOrNull?.data.id,
    );
    final posts = items
        .map((e) => PostData(e)..setLevel(post.level + 1))
        .toList();
    final add = posts.whereNot((e) => _map.containsKey(e.data.msgid));
    _map.addAll({for (var post in add) post.data.msgid: post});
    post.addChildren(posts);
    _setupPosts(posts);
  }

  void _setupPosts(Iterable<PostData> posts) {
    for (var post in posts) {
      _loadTextFile(post);
      final qMsgid = _getQuote(post);
      if (_map.containsKey(qMsgid)) post.setQuote(_map[qMsgid]!);
    }
    _sync(posts.map((e) => e.data));
  }

  Future<void> _sync(Iterable<Post> posts) async {
    final cloud = Modular.get<CloudService>();
    final futures = await cloud.syncPosts(posts.where((e) => e.text == null));
    for (var e in futures.entries) {
      if (_map.containsKey(e.key)) {
        e.value.then((v) {
          if (v == null) {
            _map[e.key]?.syncError();
          } else {
            _map[e.key]?.syncFrom(v);
            _loadTextFile(_map[e.key]!);
          }
        });
      }
    }
  }

  Future<void> resync(PostData post) async {
    post.syncRetry();
    final cloud = Modular.get<CloudService>();
    final items = await cloud.getPostsByMsgids([post.data.msgid]);
    final data = items.firstOrNull;
    if (data != null && data.text != null) {
      post.syncFrom(data);
    } else {
      _sync([post._data]);
    }
  }

  String? _getQuote(PostData post) {
    final data = post.data;
    if (data.ref.isEmpty || postMode.value) return null;

    String previous = '';
    for (var e in [...pItems.value]) {
      if (e.data.msgid == data.msgid && previous == data.ref.last) {
        return null;
      }
      previous = e.data.msgid;
    }
    return data.ref.last;
  }

  Future<void> loadQuote(PostData post) async {
    if (postMode.value) return;
    if (post.quote.value != null) return;
    final qMsgid = _getQuote(post);
    if (qMsgid == null) return;
    if (!_map.containsKey(qMsgid)) {
      final cloud = Modular.get<CloudService>();
      final items = await cloud.getPostsByMsgids([qMsgid]);
      final quote = items.firstOrNull;
      if (quote != null) {
        final data = PostData(quote);
        _map[qMsgid] = data;
        _setupPosts([data]);
      }
    }
    if (!_map.containsKey(qMsgid)) return;
    post.setQuote(_map[qMsgid]!);
  }

  Future<void> _loadTextFile(PostData post) async {
    if (post.data.textFile == null) return;
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(post.data.textFile!);
    post.setText(utf8.decode(data));
  }

  Future<void> loadImage(PostData post) async {
    if (!post.synced.value) return;
    for (var id in post.data.files) {
      final image = await _loadImageData(id);
      post.setImage(id, image);
    }
  }

  Future<ImageData> _loadImageData(String id) async {
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(id);
    final size = await getImageSize(data);
    return ImageData(data, size);
  }
}
