import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/const.dart';
import '../app/string_utils.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'thread_store.dart';

class PostData extends ChangeNotifier {
  SelectedListenable<bool, bool?> get synced => _sync.select((e) => e == true);
  SelectedListenable<bool, bool?> get syncing =>
      _sync.select((e) => e == false);
  SelectedListenable<bool, bool?> get error => _sync.select((e) => e == null);
  final _sync = ValueNotifier<bool?>(false);

  ValueListenable<PostData?> get quote => _quote;
  final _quote = ValueNotifier<PostData?>(null);

  Iterable<ValueNotifier<ImageData?>> get images => _images.values;
  Map<String, ValueNotifier<ImageData?>> _images = {};

  ValueListenable<bool> get original => _original;
  final _original = ValueNotifier<bool>(false);

  ValueListenable<bool> get read => _read;
  final _read = ValueNotifier<bool>(false);

  Post get data => _data;
  Post _data;

  String? _text;
  bool _visible = false;
  Timer? _visibleTimer;

  PostData(Post post) : _data = post {
    if (post.text == null) return;
    _sync.value = post.textFile == null;
    _images = {for (var id in post.files) id: ValueNotifier<ImageData?>(null)};
  }

  void syncFrom(Post post) {
    _data = post;
    _images = {for (var id in post.files) id: ValueNotifier<ImageData?>(null)};
    _sync.value = post.textFile == null;
    setVisible(_visible);
    notifyListeners();
  }

  void syncError() {
    _sync.value = null;
    notifyListeners();
  }

  void setText(String text) {
    _text = text;
    _sync.value = true;
    setVisible(_visible);
    notifyListeners();
  }

  void setQuote(PostData post) {
    _quote.value = post;
    notifyListeners();
  }

  void setImage(String id, ImageData data) {
    _images[id]?.value = data;
    notifyListeners();
  }

  void setOriginal(bool value) {
    _original.value = value;
    notifyListeners();
  }

  String getText() {
    final text = (_text ?? data.text ?? '');
    final strip = original.value ? text : text.stripAll;
    return switch (_sync.value) {
      null => syncTimeoutText,
      false => syncBodyText,
      true => (strip.isEmpty && data.files.isEmpty) ? emptyText : strip,
    };
  }

  Future<void> setVisible(bool v) async {
    _visibleTimer?.cancel();
    _visibleTimer = Timer(1.seconds, () {
      _visible = v;
      if (_visible && synced.value) {
        _read.value = true;
        notifyListeners();
      }
    });
  }
}

class ImageData {
  // String name;
  Uint8List data;
  Size size;
  ImageData(this.data, this.size);
}

class PostStore {
  ListListenable<PostData> get pItems => _pItems;
  final _pItems = ListNotifier<PostData>([]);

  bool get reachEnd => _reachEnd;
  var _reachEnd = true;

  int get selected => _select.value;
  final _select = ValueNotifier<int>(0);

  final _map = <String, PostData>{};

  static const _itemsPreFetch = 25;

  String? _cursorEnd;

  Listenable get all => Listenable.merge(_map.values);

  void refresh() {
    _cursorEnd = null;
    _reachEnd = false;
    _pItems.clear();
    _map.clear();
  }

  Future<void> loadMore() async {
    final threads = Modular.get<ThreadStore>();
    if (_reachEnd || threads.selected == null) return;
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getPosts(
      threads.selected!.data.msgid,
      _itemsPreFetch,
      _cursorEnd,
    );
    _reachEnd = items.isEmpty || items.length < _itemsPreFetch;
    if (_reachEnd) {
      _cursorEnd = null;
    } else {
      _cursorEnd = items.last.id;
    }
    final posts = items.map((e) => PostData(e)).toList();
    final add = posts.whereNot((e) => _map.containsKey(e.data.msgid));
    _map.addAll({for (var post in add) post.data.msgid: post});
    _pItems.append(posts);

    for (var post in posts) {
      _loadTextFile(post);
      final qMsgid = _getQuote(post);
      if (_map.containsKey(qMsgid)) post.setQuote(_map[qMsgid]!);
    }
    sync(items);
  }

  Future<void> sync(Iterable<Post> posts) async {
    final cloud = Modular.get<CloudService>();
    final futures = await cloud.syncPosts(posts.where((e) => e.text == null));
    for (var e in futures.entries) {
      if (_map.containsKey(e.key)) {
        e.value.then((v) {
          _map[e.key]?.syncError();
          if (v == null) {
          } else {
            _map[e.key]?.syncFrom(v);
            _loadTextFile(_map[e.key]!);
          }
        });
      }
    }
  }

  String? _getQuote(PostData post) {
    final data = post.data;
    if (data.ref.isEmpty) return null;

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
    if (post.quote.value != null) return;
    final qMsgid = _getQuote(post);
    if (qMsgid == null) return;
    if (!_map.containsKey(qMsgid)) {
      final cloud = Modular.get<CloudService>();
      final quote = await cloud.getPost(qMsgid);
      if (quote != null) _map[qMsgid] = PostData(quote);
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
    if (post.images.every((e) => e.value != null)) return;
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
