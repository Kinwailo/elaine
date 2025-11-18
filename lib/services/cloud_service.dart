import 'package:flutter/foundation.dart';

import 'models.dart';

typedef RowData = Map<String, dynamic>;

abstract class CloudService {
  Future<List<GroupData>> getGroups(List<String> groups);

  Future<void> refreshGroups(List<GroupData> groups);

  Future<ThreadData?> getThread(String group, int number);

  Future<List<ThreadData>> getThreads(
    List<GroupData> groups,
    int limit,
    String? cursor,
  );

  Future<PostData?> getPost(String msgid);

  Future<List<PostData>> getPosts(String msgid, int limit, String? cursor);

  Future<Uint8List> getFile(String id);
}
