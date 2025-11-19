import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';

class PostTileData {
  final PostData data;
  late final ValueNotifier<PostData?> quote;
  late final List<ValueNotifier<ImageData?>> images;

  PostTileData(this.data) {
    quote = ValueNotifier<PostData?>(null);
    images = [];
    for (var _ in data.files) {
      images.add(ValueNotifier<ImageData?>(null));
    }
  }
}

class ImageData {
  Uint8List data;
  Size size;
  ImageData(this.data, this.size);
}

class HomeStore {
  ListListenable<GroupData> get currentGroups => _currentGroups;
  final _currentGroups = ListNotifier<GroupData>([]);

  ListListenable<ThreadData> get threads => _threads;
  final _threads = ListNotifier<ThreadData>([]);
  bool get noMoreThreads => _noMoreThreads;
  var _noMoreThreads = false;
  ThreadDataListenable get currentThread => _currentThread;
  final _currentThread = ThreadDataNotifier(ThreadData({}));

  ListListenable<PostData> get posts => _posts;
  final _posts = ListNotifier<PostData>([]);
  bool get noMorePosts => _noMorePosts;
  var _noMorePosts = false;
  PostDataListenable get currentPost => _currentPost;
  final _currentPost = PostDataNotifier(PostData({}));

  static const _itemsPreFetch = 25;

  String? _cursorThreads;
  String? _cursorPosts;

  final _postsTile = <String, PostTileData>{};

  final currentThreadTile = ValueNotifier<int?>(null);

  HomeStore() {
    selectGroups(['general.chat']);
  }

  Future<void> selectGroups(List<String> groups) async {
    final current = _currentGroups.value.map((e) => e.group);
    if (setEquals(groups.toSet(), current.toSet())) return;
    final cloud = Modular.get<CloudService>();
    _currentGroups.value = await cloud.getGroups(groups);
    refreshThreads();
  }

  void refreshGroups() {
    final cloud = Modular.get<CloudService>();
    cloud.refreshGroups(_currentGroups.value);
  }

  Future<void> selectThread(String group, int number) async {
    var thread = threads.value
        .where((e) => e.group == group && e.number == number)
        .firstOrNull;
    if (thread == null) {
      final cloud = Modular.get<CloudService>();
      thread = await cloud.getThread(group, number);
    }
    if (thread == null) return;
    if (currentThread.number != number) refreshPosts();
    _currentThread.value = thread;
  }

  void refreshThreads() {
    _cursorThreads = null;
    _noMoreThreads = false;
    _threads.clear();
  }

  Future<void> loadMoreThreads() async {
    if (_noMoreThreads) return;
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getThreads(
      _currentGroups.value,
      _itemsPreFetch,
      _cursorThreads,
    );
    _noMoreThreads = items.isEmpty || items.length < _itemsPreFetch;
    if (_noMoreThreads) {
      _cursorThreads = null;
    } else {
      _cursorThreads = items.last.id;
    }
    _threads.append(items);
  }

  void refreshPosts() {
    _cursorPosts = null;
    _noMorePosts = false;
    _posts.clear();
    _postsTile.clear();
  }

  Future<void> loadMorePosts() async {
    if (_noMorePosts) return;
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getPosts(
      currentThread.msgid,
      _itemsPreFetch,
      _cursorPosts,
    );
    _noMorePosts = items.isEmpty || items.length < _itemsPreFetch;
    if (_noMorePosts) {
      _cursorPosts = null;
    } else {
      _cursorPosts = items.last.id;
    }
    _postsTile.addAll({for (var item in items) item.msgid: PostTileData(item)});
    _posts.append(items);
  }

  int? getThreadTile(int? number) {
    if (currentThreadTile.value == null) {
      currentThreadTile.value = number;
    }
    return currentThreadTile.value;
  }

  int? updateThreadTile(int? number) {
    if (number != null) {
      currentThreadTile.value = number;
    }
    return currentThreadTile.value;
  }

  PostData? _getPostByMsgid(String msgid) {
    final post = _posts.value.where((e) => e.msgid == msgid).firstOrNull;
    return post ?? _postsTile[msgid]?.data;
  }

  Future<PostData?> _getQuote(String msgid) async {
    final post = _getPostByMsgid(msgid);
    if (post == null || post.ref.isEmpty) return null;
    PostData? previous;

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
      if (quote != null) _postsTile[quote.msgid] = PostTileData(quote);
    }
    return quote;
  }

  ValueNotifier<PostData?> getQuoteNotifier(String msgid) {
    return _postsTile[msgid]!.quote;
  }

  ValueNotifier<PostData?> setQuoteNotifier(String msgid) {
    final quote = getQuoteNotifier(msgid);
    if (quote.value != null) return quote;
    _getQuote(msgid).then((value) {
      quote.value = value;
    });
    return quote;
  }

  Listenable get allQuotesListenable =>
      Listenable.merge(_postsTile.values.map((e) => e.quote));

  Future<ImageData> _getImageData(String id) async {
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(id);
    final size = await getImageSize(data);
    return ImageData(data, size);
  }

  List<ValueNotifier<ImageData?>> getFilesNotifier(String msgid) {
    return _postsTile[msgid]?.images ?? [];
  }

  List<ValueNotifier<ImageData?>> setFilesNotifier(String msgid) {
    final images = _postsTile[msgid]?.images;
    if (images == null) return [];
    if (images.any((e) => e.value != null)) return images;
    final data = _getPostByMsgid(
      msgid,
    )?.files.map((e) => _getImageData(e)).toList();
    if (data == null) return [];
    final zipped = IterableZip([data, images]);
    for (var pair in zipped) {
      (pair[0] as Future<ImageData>).then((value) {
        (pair[1] as ValueNotifier<ImageData?>).value = value;
      });
    }
    return images;
  }

  Listenable get allImagesListenable =>
      Listenable.merge(_postsTile.values.map((e) => e.images).flattened);
}
