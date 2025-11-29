import 'dart:math';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';
import 'thread_store.dart';

const String defaultGroup = 'general.chat';

class GroupData {
  final Group data;
  late int number;

  GroupData(this.data) {
    number = data.number;
  }
}

class HomeStore {
  ListListenable<Group> get groups => _groups;
  final _groups = ListNotifier<Group>([]);
  final _groupMap = <String, GroupData>{};

  Set<String> get followeds => Set.unmodifiable(_followeds);
  final _followeds = <String>{};
  String get selected => _selected;
  String _selected = '';

  ValueListenable<bool> get refreshing => _refreshing;
  final _refreshing = ValueNotifier<bool>(false);

  ValueListenable<int> get syncTotal => _syncTotal;
  final _syncTotal = ValueNotifier<int>(0);

  HomeStore() {
    final cloud = Modular.get<CloudService>();
    cloud.getGroups().then((e) => _groups.value = e);
    selectGroup('general.chat');
  }

  Future<void> _updateGroupMap() async {
    final cloud = Modular.get<CloudService>();
    final groups = await cloud.getGroups(groups: [_selected]);
    _groupMap.clear();
    _groupMap.addAll({for (var g in groups) g.group: GroupData(g)});
  }

  Future<void> selectGroup(String group) async {
    if (_selected != group) {
      _selected = group;
      await _updateGroupMap();
      final threads = Modular.get<ThreadStore>();
      threads.refresh();
    }
  }

  Future<void> refreshGroups() async {
    _refreshing.value = true;
    await _updateGroupMap();
    final threads = Modular.get<ThreadStore>();
    threads.refresh();

    final cloud = Modular.get<CloudService>();
    final groups = await cloud
        .getGroups(groups: [_selected])
        .timeout(10.seconds);
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
