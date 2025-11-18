import 'package:flutter/foundation.dart';

import '../app/utils.dart';
import 'models.dart';

typedef RowData = Map<String, dynamic>;

abstract class CloudService {
  ListListenable<GroupData> get currentGroups;
  ThreadDataListenable get currentThread;
  PostDataListenable get currentPost;

  ListListenable<ThreadData> get threads;
  bool get noMoreThreads;
  ListListenable<PostData> get posts;
  bool get noMorePosts;

  Future<void> selectGroups(List<String> groups);
  void refreshGroups();
  Future<void> selectThread(String group, int number);
  void refreshThreads();
  Future<void> loadMoreThreads();
  Future<void> selectPost(String msgid);
  void refreshPosts();
  Future<void> loadMorePosts();
  Future<PostData?> getQuote(int index);
  Future<Uint8List> getFile(String id);
}
