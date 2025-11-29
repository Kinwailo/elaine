import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'thread_store.dart';

typedef PostNotifier = ValueNotifier<Post>;
typedef QuoteNotifier = ValueNotifier<Post?>;
typedef ImageNotifier = ValueNotifier<ImageData?>;
typedef ImageNotifierList = ListNotifier<ImageNotifier>;

class PostData {
  final data = PostNotifier(Post({}));
  late final QuoteNotifier quote;
  late final ImageNotifierList images;

  PostData(Post post) {
    data.value = post;
    quote = QuoteNotifier(null);
    images = ListNotifier<ImageNotifier>(
      post.files.map((_) => ImageNotifier(null)).toList(),
    );
  }

  void setData(Post post) {
    data.value = post;
    images.value = post.files.map((_) => ImageNotifier(null)).toList();
  }
}

class ImageData {
  Uint8List data;
  Size size;
  ImageData(this.data, this.size);
}

class PostStore {
  ListListenable<Post> get posts => _pItems;
  final _pItems = ListNotifier<Post>([]);

  bool get reachEnd => _reachEnd;
  var _reachEnd = true;

  Post get selected => _select.value;
  final _select = ValueNotifier<Post>(Post({}));

  final _postMap = <String, PostData>{};

  static const _itemsPreFetch = 25;

  String? _cursorEnd;

  Listenable get allPostsListenable =>
      Listenable.merge(_postMap.values.map((e) => e.data));

  void refresh() {
    _cursorEnd = null;
    _reachEnd = false;
    _pItems.clear();
    _postMap.clear();
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
    for (var item in items) {
      _postMap.putIfAbsent(item.msgid, () => PostData(item)).setData(item);
    }
    _pItems.append(items);

    final futures = await cloud.syncPosts(items.where((e) => e.text == null));
    for (var e in futures.entries) {
      if (_postMap.containsKey(e.key)) {
        e.value.then((v) => _postMap[e.key]?.setData(v));
      }
    }
  }

  PostNotifier? getPostNotifier(String msgid) {
    return _postMap[msgid]?.data;
  }

  String getPostText(String msgid) {
    final post = _getPost(msgid);
    if (post == null || post.text == null) return syncBodyText;
    final text = post.text!;
    return (text.isEmpty && post.files.isEmpty) ? emptyText : text;
  }

  Post? _getPost(String msgid) {
    return _postMap[msgid]?.data.value;
  }

  Future<Post?> _getQuote(String msgid) async {
    final post = _getPost(msgid);
    if (post == null || post.ref.isEmpty) return null;
    Post? previous;

    for (var e in posts.value) {
      if (e.msgid == post.msgid && previous?.msgid == post.ref.last) {
        return null;
      }
      previous = e;
    }
    var quote = posts.value.where((e) => e.msgid == post.ref.last).firstOrNull;
    if (quote == null) {
      final cloud = Modular.get<CloudService>();
      quote = await cloud.getPost(post.ref.last);
      if (quote != null) _postMap[quote.msgid] = PostData(quote);
    }
    return quote;
  }

  QuoteNotifier getQuoteNotifier(String msgid) {
    return _postMap[msgid]!.quote;
  }

  QuoteNotifier setQuoteNotifier(String msgid) {
    final quote = getQuoteNotifier(msgid);
    if (quote.value != null) return quote;
    _getQuote(msgid).then((value) {
      quote.value = value;
    });
    return quote;
  }

  Listenable get allQuotesListenable =>
      Listenable.merge(_postMap.values.map((e) => e.quote));

  Listenable get allQuotesTextListenable => Listenable.merge(
    _postMap.values
        .map((e) => e.quote)
        .nonNulls
        .map((e) => getPostNotifier(e.value?.msgid ?? '')),
  );

  Future<ImageData> _getImageData(String id) async {
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(id);
    final size = await getImageSize(data);
    return ImageData(data, size);
  }

  ImageNotifierList? getFilesNotifier(String msgid) {
    return _postMap[msgid]?.images;
  }

  ImageNotifierList setFilesNotifier(String msgid) {
    final images = getFilesNotifier(msgid);
    if (images == null) return ImageNotifierList([]);
    if (images.value.every((e) => e.value != null)) return images;
    final data = _getPost(msgid)?.files.map((e) => _getImageData(e)).toList();
    if (data == null) return ImageNotifierList([]);
    final zipped = IterableZip([data, images.value]);
    for (var pair in zipped) {
      (pair[0] as Future<ImageData>).then((value) {
        (pair[1] as ImageNotifier).value = value;
      });
    }
    return images;
  }

  Listenable get allImagesListenable => Listenable.merge([
    ..._postMap.values.map((e) => e.images),
    ..._postMap.values.map((e) => e.images.value).flattened,
  ]);
}
