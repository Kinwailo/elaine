import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/const.dart';
import '../app/string_utils.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'thread_store.dart';

class PostData {
  ValueListenable<bool?> get sync => _sync;
  final _sync = ValueNotifier<bool?>(false);

  ValueListenable<PostData?> get quote => _quote;
  final _quote = ValueNotifier<PostData?>(null);

  List<ValueNotifier<ImageData?>> get images => List.unmodifiable(_images);
  final _images = <ValueNotifier<ImageData?>>[];

  Post get data => _data;
  Post _data;

  String? _text;

  Listenable get changed => Listenable.merge([sync, quote, ...images]);

  PostData(Post post) : _data = post {
    if (post.text != null) {
      _sync.value = post.textFile == null;
      _images.addAll(post.files.map((e) => ValueNotifier<ImageData?>(null)));
    }
  }

  void syncFrom(Post post) {
    _data = post;
    _images.addAll(post.files.map((e) => ValueNotifier<ImageData?>(null)));
    _sync.value = post.textFile == null;
  }

  void syncError() {
    _sync.value = null;
  }

  void setText(String text) {
    _text = text;
    _sync.value = true;
  }

  void setQuote(PostData post) {
    _quote.value = post;
  }

  void setImage(int index, ImageData data) {
    _images[index].value = data;
  }

  String getText() {
    final text = (_text ?? data.text ?? '').stripAll;
    return switch (sync.value) {
      null => syncTimeoutText,
      false => syncBodyText,
      true => (text.isEmpty && data.files.isEmpty) ? emptyText : text,
    };
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

  Post get selected => _select.value;
  final _select = ValueNotifier<Post>(Post({}));

  final _map = <String, PostData>{};

  static const _itemsPreFetch = 25;

  String? _cursorEnd;

  Listenable get all => Listenable.merge(_map.values.map((e) => e.changed));

  void refresh() {
    _cursorEnd = null;
    _reachEnd = false;
    _pItems.clear();
    _map.clear();
  }

  Future<void> loadMore() async {
    if (_reachEnd) return;
    final threads = Modular.get<ThreadStore>();
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getPosts(
      threads.selected.msgid,
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
    _map.addAll({for (var post in posts) post.data.msgid: post});
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

  void loadImage(PostData post) {
    if (post.sync.value != true) return;
    for (var (i, _) in post.data.files.indexed) {
      _loadImageData(post, i);
    }
  }

  Future<void> _loadTextFile(PostData post) async {
    if (post.data.textFile == null) return;
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(post.data.textFile!);
    post.setText(utf8.decode(data));
  }

  Future<void> _loadImageData(PostData post, int index) async {
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(post.data.files[index]);
    final size = await getImageSize(data);
    post.setImage(index, ImageData(data, size));
  }
}
