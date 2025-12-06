import 'dart:math';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/data_store.dart';
import 'thread_store.dart';

const String defaultGroup = 'general.chat';

class GroupData {
  final Group data;

  DateTime get lastRefresh => _lastRefresh;
  late DateTime _lastRefresh;
  late DateTime _latestRefresh;

  final DataValue _dataValue;

  GroupData(this.data) : _dataValue = DataValue(data.group, 'info') {
    _lastRefresh =
        DateTime.tryParse(_dataValue.get('lastRefresh') ?? '') ?? refDateTime;
    _latestRefresh =
        DateTime.tryParse(_dataValue.get('latestRefresh') ?? '') ?? refDateTime;
  }

  void update() {
    _lastRefresh = _latestRefresh;
    _dataValue.set('lastRefresh', _lastRefresh.toIso8601String());
    _latestRefresh = DateTime.now();
    _dataValue.set('latestRefresh', _latestRefresh.toIso8601String());
  }
}

class GroupStore {
  ListListenable<GroupData> get items => _items;
  final _items = ListNotifier<GroupData>([]);

  final _map = <String, GroupData>{};

  List<GroupData> get subscribed => [
    if (_selected.value != null) _selected.value!,
    ..._followed.value,
  ];
  ValueListenable<GroupData?> get selected => _selected;
  final _selected = ValueNotifier<GroupData?>(null);
  final _followed = ListNotifier<GroupData>([]);

  ValueListenable<bool> get refreshing => _refreshing;
  final _refreshing = ValueNotifier<bool>(false);

  ValueListenable<int> get syncTotal => _syncTotal;
  final _syncTotal = ValueNotifier<int>(0);

  GroupStore() {
    select(null);
  }

  GroupData? get(String group) {
    return _map[group];
  }

  Future<void> select(String? group) async {
    if (items.isEmpty) {
      final cloud = Modular.get<CloudService>();
      final groups = (await cloud.getGroups())
          .map((e) => GroupData(e))
          .toList();
      if (items.isEmpty) {
        _map.addAll({for (var group in groups) group.data.group: group});
        _items.append(groups);
      }
    }
    if (_selected.value?.data.group == group) return;
    _selected.value = items.value.firstWhereOrNull(
      (e) => e.data.group == group,
    );
    final threads = Modular.get<ThreadStore>();
    threads.refresh();
  }

  Future<void> refresh() async {
    void update(GroupData g) => g.update();
    subscribed.forEach(update);

    _refreshing.value = true;
    final threads = Modular.get<ThreadStore>();
    threads.refresh();

    final cloud = Modular.get<CloudService>();
    final groups = await cloud.getGroups(
      groups: subscribed.map((e) => e.data.group),
    );
    final updates = groups.where(
      (e) => DateTime.now().difference(e.update).inSeconds > 5,
    );
    if (updates.isEmpty) {
      _refreshing.value = false;
      return;
    }

    final numbers = await cloud.checkGroups(updates.map((e) => e.group));
    _refreshing.value = false;

    final sync = updates.where(
      (e) => (numbers[e.group]?.elementAt(1) ?? 0) > e.number,
    );
    final total = sync.map((e) {
      final first = numbers[e.group]?.elementAt(0) ?? 0;
      final last = numbers[e.group]?.elementAt(1) ?? 0;
      return last - max<int>(first, e.number);
    }).sum;
    _syncTotal.value = total;

    if (sync.isNotEmpty) {
      final result = await cloud.syncThreads(sync);
      _syncTotal.value = result ? 0 : -1;
    }
  }
}
