import 'package:flutter/foundation.dart';

import 'models.dart';

typedef RowData = Map<String, dynamic>;
typedef SyncPostsData = Map<String, Future<Post>>;

abstract class CloudService {
  Future<List<Group>> getGroups({Iterable<String>? groups});

  Future<Map<String, List<int>>> checkGroups(Iterable<String> groups);

  Future<bool> syncThreads(Iterable<Group> groups);

  Future<Thread?> getThread(String group, int number);

  Future<List<Thread>> getThreads(
    Iterable<String> groups,
    int limit,
    String? cursor,
  );

  Future<SyncPostsData> syncPosts(Iterable<Post> posts);

  Future<Post?> getPost(String msgid);

  Future<List<Post>> getPosts(String msgid, int limit, String? cursor);

  Future<Uint8List> getFile(String id);
}
