import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/models.dart';
import 'home_store.dart';
import 'post_store.dart';

class ThreadStore {
  ListListenable<Thread> get nItems => _nItems;
  final _nItems = ListNotifier<Thread>([]);
  ListListenable<Thread> get pItems => _pItems;
  final _pItems = ListNotifier<Thread>([]);

  bool get reachStart => _reachStart;
  var _reachStart = true;
  bool get reachEnd => _reachEnd;
  var _reachEnd = true;

  Thread get selected => _select.value;
  final _select = ValueNotifier<Thread>(Thread({}));

  ValueListenable<int?> get tile => _tile;
  final _tile = ValueNotifier<int?>(null);

  static const _itemsPreFetch = 25;

  String? _cursorStart;
  String? _cursorEnd;

  Future<void> select(String group, int number) async {
    if (selected.number == number) return;
    var thread = pItems.value
        .where((e) => e.group == group && e.number == number)
        .firstOrNull;
    if (thread == null) {
      final cloud = Modular.get<CloudService>();
      thread = await cloud.getThread(group, number);
    }
    if (thread == null) return;
    _select.value = thread;

    if (_tile.value == null) {
      _pItems.append([thread]);
      _cursorStart = thread.id;
      _reachStart = false;
      _cursorEnd = thread.id;
      _reachEnd = false;
    }

    final posts = Modular.get<PostStore>();
    posts.refresh();
  }

  int? getTile(int? number) {
    if (_tile.value == null) {
      _tile.value = number;
    }
    return _tile.value;
  }

  int? updateTile(int? number) {
    if (number != null) {
      _tile.value = number;
    }
    return _tile.value;
  }

  Future<void> refresh() async {
    _cursorStart = null;
    _reachStart = true;
    _pItems.clear();
    _cursorEnd = null;
    _reachEnd = false;
    _nItems.clear();
    _tile.value = null;
  }

  Future<void> prependMore() async {
    if (_reachStart || _cursorStart == null) return;
    final home = Modular.get<HomeStore>();
    final cloud = Modular.get<CloudService>();
    final order = ['date', 'latest', 'hot'];
    final items = await cloud.getThreads(
      home.groups.value.map((e) => e.group),
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
    _nItems.append(items.reversed);
  }

  Future<void> appendMore() async {
    if (_reachEnd) return;
    final home = Modular.get<HomeStore>();
    final cloud = Modular.get<CloudService>();
    final order = ['date', 'latest', 'hot'];
    final items = await cloud.getThreads(
      home.groups.value.map((e) => e.group),
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
    _pItems.append(items);
  }
}
