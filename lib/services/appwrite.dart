import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';

import 'cloud_service.dart';

class ThreadData {
  final group = ValueNotifier<String?>(null);
  final number = ValueNotifier<int?>(null);
  final msgid = ValueNotifier<String?>(null);
  final listTile = ValueNotifier<int?>(null);
  final title = ValueNotifier<String>('');
}

class AppWrite extends CloudService {
  final client = Client()
      .setEndpoint('https://sgp.cloud.appwrite.io/v1')
      .setProject('elaine');
  late final tablesDB = TablesDB(client);
  late final storage = Storage(client);
  late final functions = Functions(client);
  late final realtime = Realtime(client);

  final _itemsPreFetch = 25;

  @override
  ListListenable<RowData> get currentGroups => _currentGroups;
  final _currentGroups = ListNotifier<RowData>([]);

  @override
  ListListenable<RowData> get threads => _threads;
  final _threads = ListNotifier<RowData>([]);
  @override
  bool get noMoreThreads => _noMoreThreads;
  var _noMoreThreads = false;
  @override
  RowDataListenable get currentThread => _currentThread;
  final _currentThread = RowDataNotifier({});

  @override
  ListListenable<RowData> get posts => _posts;
  final _posts = ListNotifier<RowData>([]);
  @override
  bool get noMorePosts => _noMorePosts;
  var _noMorePosts = false;
  @override
  RowDataListenable get currentPost => _currentPost;
  final _currentPost = RowDataNotifier({});

  String? _cursorThreads;
  String? _cursorPosts;

  AppWrite() {
    selectGroups(['general.chat']);
  }

  @override
  Future<void> selectGroups(List<String> groups) async {
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'groups',
      queries: [Query.equal('group', groups), Query.limit(groups.length)],
    );
    if (rows.rows.isNotEmpty) {
      _currentGroups.value = rows.rows.map((e) => e.data).toList();
    }
  }

  @override
  Future<void> refreshGroups() async {
    final groups = <String, RowData>{
      for (var e in currentGroups.value) e['group']: e,
    };
    final channels = groups.values
        .map((e) => e[r'$id'])
        .map((e) => 'databases.elaine.tables.groups.rows.$e');
    final subscription = realtime.subscribe(channels.toList());

    for (var e in groups.keys) {
      functions.createExecution(
        functionId: 'elaine_worker',
        xasync: true,
        method: ExecutionMethod.pOST,
        headers: {'content-type': 'application/json'},
        body: '{"action":"threads","data":"$e"}',
      );
    }

    final waiting = groups.keys.toSet();
    await for (var response in subscription.stream) {
      final data = response.payload;
      waiting.remove(data['group']);
      if (waiting.isEmpty) break;
    }
    await subscription.close();
    refreshThreads();
  }

  Future<RowDatas> _getThreads() async {
    if (currentGroups.isEmpty) return [];
    final groups = currentGroups.value.map<String>((e) => e['group']).toList();
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'threads',
      queries: [
        Query.equal('group', groups),
        Query.orderDesc('date'),
        Query.limit(_itemsPreFetch),
        if (_cursorThreads != null) Query.cursorAfter(_cursorThreads!),
      ],
    );
    if (rows.rows.isNotEmpty) {
      _cursorThreads = rows.rows[rows.rows.length - 1].$id;
    }
    return rows.rows.map((e) => e.data).toList();
  }

  @override
  Future<void> selectThread(String group, int number) async {
    var thread = threads.value
        .where((e) => e['group'] == group && e['num'] == number)
        .firstOrNull;
    if (thread == null) {
      final rows = await tablesDB.listRows(
        databaseId: 'elaine',
        tableId: 'threads',
        queries: [
          Query.equal('group', group),
          Query.equal('num', number),
          Query.limit(1),
        ],
      );
      if (rows.rows.isNotEmpty) thread = rows.rows[0].data;
    }
    if (thread == null) return;
    if (currentThread['num'] != number) refreshPosts();
    _currentThread.value = thread;
  }

  @override
  void refreshThreads() {
    _cursorThreads = null;
    _noMoreThreads = false;
    _threads.clear();
  }

  @override
  Future<void> loadMoreThreads() async {
    if (_noMoreThreads) return;
    var items = await _getThreads();
    _noMoreThreads = items.isEmpty || items.length < _itemsPreFetch;
    if (_noMoreThreads) _cursorThreads = null;
    _threads.addAll(items);
  }

  Future<RowDatas> _getPosts() async {
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'posts',
      queries: [
        Query.equal('thread', currentThread['msgid']),
        Query.orderAsc('num'),
        Query.limit(_itemsPreFetch),
        if (_cursorPosts != null) Query.cursorAfter(_cursorPosts!),
      ],
    );
    if (rows.rows.isNotEmpty) {
      _cursorPosts = rows.rows[rows.rows.length - 1].$id;
    }
    return rows.rows.map((e) => e.data).toList();
  }

  @override
  Future<void> selectPost(String msgid) async {}

  @override
  void refreshPosts() {
    _cursorPosts = null;
    _noMorePosts = false;
    _posts.clear();
  }

  @override
  Future<void> loadMorePosts() async {
    if (_noMorePosts) return;
    var items = await _getPosts();
    _noMorePosts = items.isEmpty || items.length < _itemsPreFetch;
    if (_noMorePosts) _cursorPosts = null;
    _posts.addAll(items);
  }

  @override
  Future<RowData?> getQuote(int index) async {
    RowData? quote;
    final post = posts.value[index];
    final ref = post['ref'] as List;
    if (index == 0 || ref.isEmpty) return quote;
    if (posts.value[index - 1]['msgid'] == ref.last) return quote;
    quote = posts.value.where((e) => e['msgid'] == ref.last).firstOrNull;
    if (quote == null) {
      var rows = await tablesDB.listRows(
        databaseId: 'elaine',
        tableId: 'posts',
        queries: [Query.equal('msgid', ref.last), Query.limit(1)],
      );
      if (rows.rows.isNotEmpty) quote = rows.rows[0].data;
    }
    return quote;
  }

  @override
  Future<Uint8List> getFile(String id) async {
    return await storage.getFileDownload(bucketId: 'elaine', fileId: id);
  }
}
