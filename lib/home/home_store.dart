import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:meta_seo/meta_seo.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';

typedef PostNotifier = ValueNotifier<Post>;
typedef QuoteNotifier = ValueNotifier<Post?>;
typedef ImageNotifier = ValueNotifier<ImageData?>;
typedef ImageNotifierList = ListNotifier<ImageNotifier>;

const String defaultGroup = 'general.chat';

class GroupData {
  final Group data;
  late int number;

  GroupData(this.data) {
    number = data.number;
  }
}

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

    if (kIsWeb) {
      final meta = MetaSEO();
      meta.ogTitle(ogTitle: thread.subject);
    }
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

  Listenable get allPostsListenable =>
      Listenable.merge(_postMap.values.map((e) => e.data));

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
    for (var item in items) {
      _postMap.putIfAbsent(item.msgid, () => PostData(item)).setData(item);
    }
    _posts.append(items);

    final futures = await cloud.syncPosts(items.where((e) => e.text == null));
    for (var e in futures.entries) {
      if (_postMap.containsKey(e.key)) {
        e.value.then((v) => _postMap[e.key]?.setData(v));
      }
    }

    if (kIsWeb) {
      final meta = MetaSEO();
      meta.ogDescription(ogDescription: getPostText(_posts[0].msgid));
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
