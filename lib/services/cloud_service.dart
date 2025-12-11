import 'package:flutter/foundation.dart';

import 'models.dart';

typedef RowData = Map<String, dynamic>;
typedef SyncPostsData = Map<String, Future<Post?>>;

abstract class CloudService {
  Future<List<Group>> getGroups({Iterable<String>? groups});

  Future<Map<String, List<int>>> checkGroups(Iterable<String> groups);

  Future<bool> syncThreads(Iterable<Group> groups);

  Future<Thread?> getThread(String group, int number);

  Future<List<Thread>> getThreads(
    Iterable<String> groups,
    int limit,
    Iterable<String> order, {
    String? cursor,
    bool reverse = false,
  });

  Future<SyncPostsData> syncPosts(Iterable<Post> posts);

  Future<Post?> getPost(String thread, int index);

  Future<List<Post>> getPosts(
    String msgid,
    int limit, {
    String? cursor,
    bool reverse = false,
  });

  Future<List<Post>> getPostsByMsgids(Iterable<String> msgids);

  Future<List<Post>> getPostsByQuote(String quote, int limit, {String? cursor});

  Future<Uint8List> getFile(String id);
}
