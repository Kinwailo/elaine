import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';

import 'cloud_service.dart';
import 'models.dart';

class AppWrite extends CloudService {
  final client = Client()
      .setEndpoint('https://sgp.cloud.appwrite.io/v1')
      .setProject('elaine');
  late final tablesDB = TablesDB(client);
  late final storage = Storage(client);
  late final functions = Functions(client);
  late final realtime = Realtime(client);

  @override
  Future<List<GroupData>> getGroups(List<String> groups) async {
    var result = <GroupData>[];
    if (groups.isEmpty) return result;
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'groups',
      queries: [Query.equal('group', groups), Query.limit(groups.length)],
    );
    if (rows.rows.isNotEmpty) {
      result = rows.rows.map((e) => GroupData(e.data)).toList();
    }
    return result;
  }

  @override
  Future<void> refreshGroups(List<GroupData> groups) async {
    final map = <String, GroupData>{for (var e in groups) e.group: e};
    final channels = map.values
        .map((e) => e.id)
        .map((e) => 'databases.elaine.tables.groups.rows.$e');
    final subscription = realtime.subscribe(channels.toList());

    for (var e in map.keys) {
      functions.createExecution(
        functionId: 'elaine_worker',
        xasync: true,
        method: ExecutionMethod.pOST,
        headers: {'content-type': 'application/json'},
        body: '{"action":"threads","data":"$e"}',
      );
    }

    final waiting = map.keys.toSet();
    await for (var response in subscription.stream) {
      final data = response.payload;
      waiting.remove(data['group']);
      if (waiting.isEmpty) break;
    }
    await subscription.close();
  }

  @override
  Future<ThreadData?> getThread(String group, int number) async {
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'threads',
      queries: [
        Query.equal('group', group),
        Query.equal('num', number),
        Query.limit(1),
      ],
    );
    if (rows.rows.isEmpty) return null;
    return ThreadData(rows.rows[0].data);
  }

  @override
  Future<List<ThreadData>> getThreads(
    List<GroupData> groups,
    int limit,
    String? cursor,
  ) async {
    if (groups.isEmpty) return [];
    final names = groups.map((e) => e.group).toList();
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'threads',
      queries: [
        Query.equal('group', names),
        Query.orderDesc('date'),
        Query.limit(limit),
        if (cursor != null) Query.cursorAfter(cursor),
      ],
    );
    return rows.rows.map((e) => ThreadData(e.data)).toList();
  }

  @override
  Future<PostData?> getPost(String msgid) async {
    var rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'posts',
      queries: [Query.equal('msgid', msgid), Query.limit(1)],
    );
    if (rows.rows.isEmpty) return null;
    return PostData(rows.rows[0].data);
  }

  @override
  Future<List<PostData>> getPosts(
    String msgid,
    int limit,
    String? cursor,
  ) async {
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'posts',
      queries: [
        Query.equal('thread', msgid),
        Query.orderAsc('num'),
        Query.limit(limit),
        if (cursor != null) Query.cursorAfter(cursor),
      ],
    );
    return rows.rows.map((e) => PostData(e.data)).toList();
  }

  @override
  Future<Uint8List> getFile(String id) async {
    return await storage.getFileDownload(bucketId: 'elaine', fileId: id);
  }
}
