import 'package:flutter/foundation.dart';

typedef RowData = Map<String, dynamic>;
typedef RowDatas = List<RowData>;
typedef RowDataListenable = MapListenable<String, dynamic>;
typedef RowDataNotifier = MapNotifier<String, dynamic>;

abstract class CloudService {
  ListListenable<RowData> get currentGroups;
  RowDataListenable get currentThread;
  RowDataListenable get currentPost;

  ListListenable<RowData> get threads;
  bool get noMoreThreads;
  ListListenable<RowData> get posts;
  bool get noMorePosts;

  Future<void> selectGroups(List<String> groups);
  void refreshGroups();
  Future<void> selectThread(String group, int number);
  void refreshThreads();
  Future<void> loadMoreThreads();
  Future<void> selectPost(String msgid);
  void refreshPosts();
  Future<void> loadMorePosts();
  Future<RowData?> getQuote(int index);
  Future<Uint8List> getFile(String id);
}

abstract class ListListenable<T> extends Listenable {
  const ListListenable();
  List<T> get value;
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;
  T operator [](int index);
}

class ListNotifier<T> extends ValueNotifier<List<T>>
    implements ListListenable<T> {
  ListNotifier(super.value);

  @override
  int get length => value.length;
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  T operator [](int index) {
    if (index >= 0 && index < value.length) {
      return value[index];
    }
    throw RangeError.index(index, value, 'index', null, value.length);
  }

  void clear() {
    value = [];
  }

  void addAll(Iterable<T> items) {
    value = [...value, ...items];
  }
}

abstract class MapListenable<K, V> extends Listenable {
  const MapListenable();
  Map<K, V> get value;
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;
  V? operator [](Object? key);
}

class MapNotifier<K, V> extends ValueNotifier<Map<K, V>>
    implements MapListenable<K, V> {
  MapNotifier(super.value);

  @override
  int get length => value.length;
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  V? operator [](Object? key) {
    if (key is K) {
      return value[key];
    }
    return null;
  }

  void clear() {
    value = {};
  }

  void addAll(Map<K, V> items) {
    value = {...value, ...items};
  }
}
