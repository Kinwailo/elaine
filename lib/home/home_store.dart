import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';

typedef QuoteNotifier = ValueNotifier<Post?>;
typedef ImageNotifierList = List<ValueNotifier<ImageData?>>;

const String defaultGroup = 'general.chat';

class GroupData {
  final Group data;
  late int number;

  GroupData(this.data) {
    number = data.number;
  }
}

class PostData {
  final Post data;
  late final QuoteNotifier quote;
  late final ImageNotifierList images;

  PostData(this.data) {
    quote = QuoteNotifier(null);
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
  ListListenable<Group> get groups => _groups;
  final _groups = ListNotifier<Group>([]);
  final _groupMap = <String, GroupData>{};

  Set<String> get followeds => Set.unmodifiable(_followeds);
  final _followeds = <String>{};
  String get selected => _selected;
  String _selected = '';

  ListListenable<Thread> get threads => _threads;
  final _threads = ListNotifier<Thread>([]);
  bool get noMoreThreads => _noMoreThreads;
  var _noMoreThreads = true;
  Thread get thread => _thread.value;
  final _thread = ValueNotifier<Thread>(Thread({}));

  ListListenable<Post> get posts => _posts;
  final _posts = ListNotifier<Post>([]);
  bool get noMorePosts => _noMorePosts;
  var _noMorePosts = true;
  Post get post => _post.value;
  final _post = ValueNotifier<Post>(Post({}));
  final _postMap = <String, PostData>{};

  static const _itemsPreFetch = 25;

  String? _cursorThreads;
  String? _cursorPosts;

  ValueListenable<int?> get threadTile => _threadTile;
  final _threadTile = ValueNotifier<int?>(null);

  ValueListenable<bool> get refreshing => _refreshing;
  final _refreshing = ValueNotifier<bool>(false);

  ValueListenable<int> get syncTotal => _syncTotal;
  final _syncTotal = ValueNotifier<int>(0);

  HomeStore() {
    final cloud = Modular.get<CloudService>();
    cloud.getGroups().then((e) => _groups.value = e);
    selectGroup('general.chat');
  }

  Future<void> _updateGroupMap() async {
    final cloud = Modular.get<CloudService>();
    final groups = await cloud.getGroups(groups: [_selected]);
    _groupMap.clear();
    _groupMap.addAll({for (var g in groups) g.group: GroupData(g)});
  }

  Future<void> selectGroup(String group) async {
    if (_selected != group) {
      _selected = group;
      refreshThreads();
    }
  }

  Future<void> refreshGroups() async {
    _refreshing.value = true;
    refreshThreads();

    final cloud = Modular.get<CloudService>();
    final groups = await cloud
        .getGroups(groups: [_selected])
        .timeout(10.seconds);
    final update = groups.where(
      (e) => DateTime.now().difference(e.update).inSeconds > 5,
    );
    if (update.isEmpty) {
      _refreshing.value = false;
      return;
    }

    final numbers = await cloud.checkGroups(update.map((e) => e.group));
    _refreshing.value = false;

    final sync = update.where(
      (e) => (numbers[e.group]?.elementAt(1) ?? 0) > e.number,
    );
    final total = sync.map((e) {
      final first = numbers[e.group]?.elementAt(0) ?? 0;
      final last = numbers[e.group]?.elementAt(1) ?? 0;
      return last - max<int>(first, e.number);
    }).sum;
    _syncTotal.value = total;

    if (sync.isNotEmpty) {
      final result = await cloud.syncThreads(sync);
      _syncTotal.value = result ? 0 : -1;
    }
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
    if (this.thread.number != number) refreshPosts();
    _thread.value = thread;
  }

  int? getThreadTile(int? number) {
    if (_threadTile.value == null) {
      _threadTile.value = number;
    }
    return _threadTile.value;
  }

  int? updateThreadTile(int? number) {
    if (number != null) {
      _threadTile.value = number;
    }
    return _threadTile.value;
  }

  Future<void> refreshThreads() async {
    await _updateGroupMap();
    _cursorThreads = null;
    _noMoreThreads = false;
    _threads.clear();
    _threadTile.value = null;
  }

  Future<void> loadMoreThreads() async {
    if (_noMoreThreads) return;
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getThreads(
      _groupMap.keys,
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
    _postMap.clear();
  }

  Future<void> loadMorePosts() async {
    if (_noMorePosts) return;
    final cloud = Modular.get<CloudService>();
    var items = await cloud.getPosts(
      thread.msgid,
      _itemsPreFetch,
      _cursorPosts,
    );
    _noMorePosts = items.isEmpty || items.length < _itemsPreFetch;
    if (_noMorePosts) {
      _cursorPosts = null;
    } else {
      _cursorPosts = items.last.id;
    }
    _postMap.addAll({for (var item in items) item.msgid: PostData(item)});
    _posts.append(items);

    final futures = await cloud.syncPosts(items.where((e) => e.text == null));
  }

  Post? _getPostByMsgid(String msgid) {
    final post = _posts.value.where((e) => e.msgid == msgid).firstOrNull;
    return post ?? _postMap[msgid]?.data;
  }

  Future<Post?> _getQuote(String msgid) async {
    final post = _getPostByMsgid(msgid);
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

  Future<ImageData> _getImageData(String id) async {
    final cloud = Modular.get<CloudService>();
    final data = await cloud.getFile(id);
    final size = await getImageSize(data);
    return ImageData(data, size);
  }

  ImageNotifierList getFilesNotifier(String msgid) {
    return _postMap[msgid]?.images ?? [];
  }

  ImageNotifierList setFilesNotifier(String msgid) {
    final images = _postMap[msgid]?.images;
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
      Listenable.merge(_postMap.values.map((e) => e.images).flattened);
}
