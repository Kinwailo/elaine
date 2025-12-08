import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
            queries: [
              Query.equal('group', [...groups]),
              Query.limit(groups.length),
            ],
          );
    return rows.rows.isEmpty
        ? []
        : rows.rows.map((e) => Group(e.data)).toList();
  }

  @override
  Future<Map<String, List<int>>> checkGroups(Iterable<String> groups) async {
    var e = await functions.createExecution(
      functionId: 'elaine_worker',
      method: ExecutionMethod.pOST,
      headers: {'content-type': 'application/json'},
      body: '{"action":"check_group","data":"${groups.first}"}',
    );
    try {
      final res = jsonDecode(e.responseBody);
      return {for (var g in groups) g: (res[g] as List).cast()};
    } catch (_) {
      return {
        for (var g in groups) g: [0, 0],
      };
    }
  }

  @override
  Future<bool> syncThreads(Iterable<Group> groups) async {
    if (groups.isEmpty) return true;
    final ids = groups.map((e) => e.id).toList();
    final channels = ids.map((e) => 'databases.elaine.tables.groups.rows.$e');
    final subscription = realtime.subscribe(channels.toList());
    final stream = subscription.stream.timeout(10.seconds);

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
    Iterable<String> order, {
    String? cursor,
    bool reverse = false,
  }) async {
    if (groups.isEmpty) return [];
    final rows = await tablesDB.listRows(
      databaseId: 'elaine',
      tableId: 'threads',
      queries: [
        Query.equal('group', groups.toList()),
        ...order.map((e) => Query.orderDesc(e)),
        Query.limit(limit),
        if (cursor != null)
          reverse ? Query.cursorBefore(cursor) : Query.cursorAfter(cursor),
      ],
    );
    return rows.rows.map((e) => Thread(e.data)).toList();
  }

  @override
  Future<SyncPostsData> syncPosts(Iterable<Post> posts) async {
    if (posts.isEmpty) return {};
    final ids = posts.map((e) => e.id).toList();
    final channels = ids.map((e) => 'databases.elaine.tables.posts.rows.$e');
    final subscription = realtime.subscribe(channels.toList());
    final stream = subscription.stream.timeout(10.seconds);

    final msgids = posts.map((e) => e.msgid).toList();
    final data = '[${msgids.map((e) => '"$e"').join(',')}]';
    functions.createExecution(
      functionId: 'elaine_worker',
      xasync: true,
      method: ExecutionMethod.pOST,
      headers: {'content-type': 'application/json'},
      body: '{"action":"get_bodies","data":$data}',
    );

    final waiting = {for (var msgid in msgids) msgid: Completer<Post?>()};
    try {
      await for (var response in stream) {
        final data = response.payload;
        waiting[data['msgid']]?.complete(Post(data));
        if (waiting.values.every((e) => e.isCompleted)) break;
      }
    } on TimeoutException catch (_) {
      for (var e in waiting.values) {
        if (!e.isCompleted) e.complete(null);
      }
    } finally {
      await subscription.close();
    }
    return {for (var e in waiting.entries) e.key: e.value.future};
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
        Query.orderAsc('index'),
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
