import 'dart:math';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/data_store.dart';
import 'thread_store.dart';

const String defaultGroup = 'general.chat';

class GroupData {
  final Group data;

  late DateTime _date;

  final DataValue _dataValue;

  GroupData(this.data) : _dataValue = DataValue(data.group, 'info') {
    _date = DateTime.tryParse(_dataValue.get('date') ?? '') ?? DateTime.now();
  }

  void update() {
    _dataValue.set('date', DateTime.now().toIso8601String());
  }
}

class HomeStore {
  ListListenable<GroupData> get groups => _groups;
  final _groups = ListNotifier<GroupData>([]);

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

  HomeStore() {
    select(null);
  }

  Future<void> select(String? group) async {
    if (groups.isEmpty) {
      final cloud = Modular.get<CloudService>();
      final items = await cloud.getGroups();
      if (groups.isEmpty) {
        final groups = items.map((e) => GroupData(e)).toList();
        _map.addAll({for (var group in groups) group.data.group: group});
        _groups.append(groups);
      }
    }
    if (_selected.value?.data.group == group) return;
    _selected.value = groups.value.firstWhereOrNull(
      (e) => e.data.group == group,
    );
    final threads = Modular.get<ThreadStore>();
    threads.refresh();
  }

  Future<void> refresh() async {
    _refreshing.value = true;
    final threads = Modular.get<ThreadStore>();
    threads.refresh();

    final cloud = Modular.get<CloudService>();
    final groups = await cloud.getGroups(
      groups: subscribed.map((e) => e.data.group),
    );
    final update = groups.where(
      (e) => DateTime.now().difference(e.update).inSeconds > 5,
    );
    if (update.isEmpty) {
      _refreshing.value = false;
      return;
    }

    final numbers = await cloud.checkGroups(update.map((e) => e.group));
    _refreshing.value = false;

    final sync = update.where(
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
