import 'package:collection/collection.dart';
import 'package:elaine/services/data_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'group_store.dart';
import 'post_store.dart';

class ThreadData {
  ValueListenable<int> get read => _read;
  final _read = ValueNotifier<int>(0);

  Thread get data => _data;
  final Thread _data;

  final DataValue _dataValue;

  ThreadData(Thread thread)
    : _data = thread,
      _dataValue = DataValue(thread.group, '${thread.number}') {
    _read.value = _dataValue.get('read') ?? 0;
  }

  void markRead(int read) {
    if (read >= _read.value) {
      _read.value = read;
      _dataValue.set('read', read);
      _dataValue.set('latestRead', DateTime.now().toIso8601String());
    }
  }
}

class ThreadStore {
  ListListenable<ThreadData> get nItems => _nItems;
  final _nItems = ListNotifier<ThreadData>([]);
  ListListenable<ThreadData> get pItems => _pItems;
  final _pItems = ListNotifier<ThreadData>([]);

  bool get reachStart => _reachStart;
  var _reachStart = true;
  bool get reachEnd => _reachEnd;
  var _reachEnd = true;

  ThreadData? get selected => _select;
  ThreadData? _select;

  final _map = <String, ThreadData>{};

  ValueListenable<int?> get tile => _tile;
  final _tile = ValueNotifier<int?>(null);

  static const _itemsPreFetch = 25;

  String? _cursorStart;
  String? _cursorEnd;

  Future<void> select(String group, int number) async {
    if (selected?.data.number == number) return;
    var thread = nItems.value
        .followedBy(pItems.value)
        .map((e) => e.data)
        .where((e) => e.group == group && e.number == number)
        .firstOrNull;
    if (thread == null) {
      final cloud = Modular.get<CloudService>();
      thread = await cloud.getThread(group, number);
    }
    if (thread == null) return;
    final data = _map.putIfAbsent(thread.msgid, () => ThreadData(thread!));
    _select = data;

    if (_tile.value == null) {
      _pItems.append([data]);
      _cursorStart = thread.id;
      _reachStart = false;
      _cursorEnd = thread.id;
      _reachEnd = false;
    }

    final posts = Modular.get<PostStore>();
    posts.refresh();
  }

  int? getTile() {
    if (_tile.value == null) {
      _tile.value = selected?._data.number;
    }
    return _tile.value;
  }

  void updateTile(int number) {
    _tile.value = number;
  }

  Future<void> refresh() async {
    _cursorStart = null;
    _reachStart = true;
    _pItems.clear();
    _cursorEnd = null;
    _reachEnd = false;
    _nItems.clear();
    _tile.value = null;
    _map.clear();
  }

  Future<void> prependMore() async {
    if (_reachStart || _cursorStart == null) return;
    final groups = Modular.get<GroupStore>();
    final cloud = Modular.get<CloudService>();
    final order = ['date', 'latest', 'hot'];
    final items = await cloud.getThreads(
      groups.subscribed.map((e) => e.data.group),
      _itemsPreFetch,
      order,
      cursor: _cursorStart,
      reverse: true,
    );
    _reachStart = items.isEmpty || items.length < _itemsPreFetch;
    if (_reachStart) {
      _cursorStart = null;
    } else {
      _cursorStart = items.first.id;
    }

    final threads = items.map((e) => ThreadData(e)).toList();
    final add = threads.whereNot((e) => _map.containsKey(e.data.msgid));
    _map.addAll({for (var thread in add) thread.data.msgid: thread});
    _nItems.append(threads.reversed);
  }

  Future<void> appendMore() async {
    if (_reachEnd) return;
    final groups = Modular.get<GroupStore>();
    final cloud = Modular.get<CloudService>();
    final order = ['date', 'latest', 'hot'];
    final items = await cloud.getThreads(
      groups.subscribed.map((e) => e.data.group),
      _itemsPreFetch,
      order,
      cursor: _cursorEnd,
    );
    _reachEnd = items.isEmpty || items.length < _itemsPreFetch;
    if (_reachEnd) {
      _cursorEnd = null;
    } else {
      _cursorEnd = items.last.id;
    }

    final threads = items.map((e) => ThreadData(e)).toList();
    final add = threads.whereNot((e) => _map.containsKey(e.data.msgid));
    _map.addAll({for (var thread in add) thread.data.msgid: thread});
    _pItems.append(threads);
  }
}
