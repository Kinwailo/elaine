import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';

class PostTileData {
  late final ValueNotifier<PostData?> quote;
  late final List<ValueNotifier<ImageData?>> images;

  PostTileData(PostData data) {
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

  final _postsTile = <PostData, PostTileData>{};

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
    _postsTile.addAll({for (var item in items) item: PostTileData(item)});
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

  Future<PostData?> _getQuote(int index) async {
    PostData? quote;
    final post = posts[index];
    final ref = post.ref as List;
    if (index == 0 || ref.isEmpty) return quote;
    if (posts[index - 1].msgid == ref.last) return quote;
    quote = posts.value.where((e) => e.msgid == ref.last).firstOrNull;
    if (quote == null) {
      final cloud = Modular.get<CloudService>();
      quote = await cloud.getPost(ref.last);
    }
    return quote;
  }

  ValueNotifier<PostData?> getQuoteNotifier(int index) {
    return _postsTile[posts[index]]!.quote;
  }

  ValueNotifier<PostData?> setQuoteNotifier(int index) {
    final quote = getQuoteNotifier(index);
    _getQuote(index).then((value) {
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

  List<ValueNotifier<ImageData?>> getFilesNotifier(int index) {
    return _postsTile[posts[index]]!.images;
  }

  List<ValueNotifier<ImageData?>> setFilesNotifier(int index) {
    final data = posts[index].files.map((e) => _getImageData(e)).toList();
    final images = _postsTile[posts[index]]!.images;
    var zipped = IterableZip([data, images]);
    for (var pair in zipped) {
      (pair[0] as Future<ImageData>).then((value) {
        (pair[1] as ValueNotifier<ImageData?>).value = value;
      });
    }
    return images;
  }

  Listenable get allImagesListenable =>
      Listenable.merge(_postsTile.values.map((e) => e.images).expand((e) => e));
}
