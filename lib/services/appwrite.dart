import 'dart:convert';

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
  Future<List<Group>> getGroups({Iterable<String>? groups}) async {
    if (groups != null && groups.isEmpty) return [];
    final rows = (groups == null)
        ? await tablesDB.listRows(
            databaseId: 'elaine',
            tableId: 'groups',
            queries: [Query.limit(100)],
          )
        : await tablesDB.listRows(
            databaseId: 'elaine',
            tableId: 'groups',
            queries: [Query.equal('group', groups), Query.limit(groups.length)],
          );
    return rows.rows.isEmpty
        ? []
        : rows.rows.map((e) => Group(e.data)).toList();
  }

  @override
  Future<Map<String, int>> checkGroups(Iterable<String> groups) async {
    var e = await functions.createExecution(
      functionId: 'elaine_worker',
      method: ExecutionMethod.pOST,
      headers: {'content-type': 'application/json'},
      body: '{"action":"check_group","data":"${groups.first}"}',
    );
    try {
      final res = jsonDecode(e.responseBody);
      return {for (var g in groups) g: res[g]};
    } catch (_) {
      return {for (var g in groups) g: 0};
    }
  }

  @override
  Future<bool> syncThreads(Iterable<Group> groups) async {
    final ids = groups.map((e) => e.id).toList();
    final channels = ids.map((e) => 'databases.elaine.tables.groups.rows.$e');
    final subscription = realtime.subscribe(channels.toList());

    final names = groups.map((e) => e.group).toList();
    for (var name in names) {
      functions.createExecution(
        functionId: 'elaine_worker',
        xasync: true,
        method: ExecutionMethod.pOST,
        headers: {'content-type': 'application/json'},
        body: '{"action":"get_threads","data":"$name"}',
      );
    }

    final waiting = names.toSet();
    final stream = subscription.stream.timeout(const Duration(seconds: 10));
    try {
      await for (var response in stream) {
        final data = response.payload;
        waiting.remove(data['group']);
        if (waiting.isEmpty) break;
      }
    } catch (_) {
      return false;
    } finally {
      await subscription.close();
    }
    return true;
  }

  @override
  Future<Thread?> getThread(String group, int number) async {
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
    return Thread(rows.rows[0].data);
  }

  @override
  Future<List<Thread>> getThreads(
    Iterable<String> groups,
    int limit,
    String? cursor,
  ) async {
    if (groups.isEmpty) return [];
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'threads',
      queries: [
        Query.equal('group', groups.toList()),
        Query.orderDesc('date'),
        Query.limit(limit),
        if (cursor != null) Query.cursorAfter(cursor),
      ],
    );
    return rows.rows.map((e) => Thread(e.data)).toList();
  }

  @override
  Future<Post?> getPost(String msgid) async {
    var rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'posts',
      queries: [Query.equal('msgid', msgid), Query.limit(1)],
    );
    if (rows.rows.isEmpty) return null;
    return Post(rows.rows[0].data);
  }

  @override
  Future<List<Post>> getPosts(String msgid, int limit, String? cursor) async {
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
    return rows.rows.map((e) => Post(e.data)).toList();
  }

  @override
  Future<Uint8List> getFile(String id) async {
    return await storage.getFileDownload(bucketId: 'elaine', fileId: id);
  }
}
