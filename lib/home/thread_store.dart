import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:bit_array/bit_array.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/data_store.dart';
import '../services/models.dart';
import 'group_store.dart';
import 'post_store.dart';

class ThreadData {
  ValueListenable<int> get read => _read;
  final _read = ValueNotifier<int>(0);
  DateTime get latestRead => _latestRead;
  late DateTime _latestRead;

  ValueListenable<int> get readArray => _readArrayCardinality;
  final _readArrayCardinality = ValueNotifier<int>(0);
  BitArray _readArray = BitArray(1);

  Thread get data => _data;
  final Thread _data;

  final DataValue _dataValue;

  ThreadData(Thread thread)
    : _data = thread,
      _dataValue = DataValue(thread.group, '${thread.number}') {
    _latestRead = parseDateTime(_dataValue.get('latestRead'));
    _read.value = _dataValue.get('read') ?? 0;
    final ra = _dataValue.get('readArray');
    _readArray = BitArray(1);
    if (ra != null && ra is String) {
      final data = base64.decode(ra);
      _readArray = BitArray.fromUint8List(data);
    }
    _readArrayCardinality.value = _readArray.cardinality;
  }

  void markRead(int read) {
    if (read >= _read.value) {
      _read.value = read;
      _dataValue.set('read', read);
      _latestRead = DateTime.now();
      _dataValue.set('latestRead', _latestRead.toIso8601String());
    }
  }

  void markIndexRead(int index) {
    if (index >= _readArray.length) _readArray.length = index + 1;
    _readArray.setBit(index);
    _readArrayCardinality.value = _readArray.cardinality;
    final data = base64.encode(_readArray.byteBuffer.asUint8List());
    _dataValue.set('readArray', data);
    _latestRead = DateTime.now();
    _dataValue.set('latestRead', _latestRead.toIso8601String());
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

  ThreadData? get selected => _selected;
  ThreadData? _selected;

  final _map = <String, ThreadData>{};

  ValueListenable<int?> get tile => _tile;
  final _tile = ValueNotifier<int?>(null);

  static const _itemsPreFetch = 25;

  String? _cursorStart;
  String? _cursorEnd;

  Future<void> select(
    String group,
    int number,
    int index,
    bool postMode,
  ) async {
    final groups = Modular.get<GroupStore>();
    final changed =
        selected?.data.number != number ||
        groups.selected.value?.data.group == group;

    if (changed) {
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
      _selected = data;

      if (_tile.value == null) {
        _cursorStart = thread.id;
        _reachStart = false;
        _cursorEnd = thread.id;
        _reachEnd = false;
        _pItems.append([data]);
      }
    }

    final posts = Modular.get<PostStore>();
    if (changed || posts.index != index || posts.postMode.value != postMode) {
      posts.select(index, postMode);
    }
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
    _nItems.clear();
    _cursorEnd = null;
    _reachEnd = false;
    _pItems.clear();
    _tile.value = null;
    _map.clear();
  }

  Future<void> loadMore({bool reverse = false}) async {
    final pass = reverse ? _reachStart || _cursorStart == null : _reachEnd;
    if (pass) return;

    final groups = Modular.get<GroupStore>();
    final cloud = Modular.get<CloudService>();
    final order = switch (DataValue('settings', 'ui').get<int>('order')) {
      1 => ['latest', 'date', 'hot'],
      2 => ['hot', 'latest', 'date'],
      _ => ['date', 'latest', 'hot'],
    };
    final items = await cloud.getThreads(
      groups.subscribed.map((e) => e.data.group),
      groups.subscribed.map((e) => e.number),
      _itemsPreFetch,
      order,
      cursor: reverse ? _cursorStart : _cursorEnd,
      reverse: reverse,
    );
    if (reverse) {
      _reachStart = items.isEmpty || items.length < _itemsPreFetch;
      _cursorStart = _reachStart ? null : items.first.id;
    } else {
      _reachEnd = items.isEmpty || items.length < _itemsPreFetch;
      _cursorEnd = _reachEnd ? null : items.last.id;
    }

    final threads = items.map((e) => ThreadData(e)).toList();
    final add = threads.whereNot((e) => _map.containsKey(e.data.msgid));
    _map.addAll({for (var thread in add) thread.data.msgid: thread});
    reverse ? _nItems.append(threads.reversed) : _pItems.append(threads);
  }
}
