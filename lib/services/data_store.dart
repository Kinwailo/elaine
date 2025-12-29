import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart';

class DataStore extends ChangeNotifier {
  DataStore._(this.name);

  static const String app = 'elaine';
  static final Map<String, DataStore> _store = {};
  static final changed = ValueNotifier('');

  final String name;

  String get path => p.join(app, name);

  static DataStore store(String name) {
    return _store.putIfAbsent(name, () => DataStore._(name));
  }

  static Iterable<String> get keys sync* {
    for (int i = 0; i < window.localStorage.length; i++) {
      yield window.localStorage.key(i)!;
    }
  }

  static Iterable<String> get list => keys
      .where((e) => p.split(e).firstOrNull == app)
      .map((e) => p.split(e).skip(1).firstOrNull)
      .nonNulls;

  Iterable<String> get datas => list
      .where((e) => p.split(e).skip(1).firstOrNull == name)
      .map((e) => p.split(e).skip(2).firstOrNull)
      .nonNulls;

  void remove(String data) {
    final path = p.join(app, name, data);
    window.localStorage.removeItem(path);
  }

  String? get(String data) {
    final path = p.join(app, name, data);
    return window.localStorage.getItem(path);
  }

  void set(String data, dynamic value, {bool notify = true}) {
    if (value == get(data)) return;
    final path = p.join(app, name, data);
    window.localStorage.setItem(path, value);
    if (notify) {
      changed.value = data;
      notifyListeners();
    }
  }
}

class DataValue extends ChangeNotifier {
  DataValue(String store, this.name) : store = DataStore.store(store) {
    getData();
  }

  static final changed = ValueNotifier<(String, dynamic)?>(null);

  final DataStore store;
  final String name;
  Map<String, dynamic>? _data;

  void getData() {
    final data = store.get(name);
    _data = data == null ? {} : json.decode(data);
  }

  Iterable<String> list() {
    return _data?.keys ?? [];
  }

  T? get<T>(String key) {
    return _data?[key] as T?;
  }

  void set(String key, dynamic value, {bool notify = true}) {
    if (value == get(key)) return;
    getData();
    _data?[key] = value;
    store.set(name, json.encode(_data ?? {}));
    if (notify) {
      changed.value = ('${store.name}.$name.$key', value);
      notifyListeners();
    }
  }
}
