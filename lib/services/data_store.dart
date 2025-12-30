import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart';

class DataStore extends ChangeNotifier {
  DataStore._(this.store);

  static const String app = 'elaine';
  static final Map<String, DataStore> _store = {};
  static final changed = ValueNotifier('');

  final String store;

  String get path => p.join(app, store);

  static DataStore getStore(String name) {
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
      .toSet()
      .nonNulls;

  Iterable<String> get names => keys
      .where((e) => p.split(e).firstOrNull == app)
      .where((e) => p.split(e).skip(1).firstOrNull == store)
      .map((e) => p.split(e).skip(2).firstOrNull)
      .nonNulls;

  void remove(String name) {
    final path = p.join(app, store, name);
    window.localStorage.removeItem(path);
  }

  String? get(String name) {
    final path = p.join(app, store, name);
    return window.localStorage.getItem(path);
  }

  Map<String, dynamic>? getData(String name) {
    final text = get(name);
    return text == null ? null : json.decode(text);
  }

  void set(String name, String data, {bool notify = true}) {
    if (data == get(name)) return;
    final path = p.join(app, store, name);
    window.localStorage.setItem(path, data);
    if (notify) {
      changed.value = name;
      notifyListeners();
    }
  }

  void setData(String name, Map<String, dynamic>? data, {bool notify = true}) {
    set(name, json.encode(data ?? {}), notify: notify);
  }
}

class DataValue extends ChangeNotifier {
  DataValue(String store, this.name) : store = DataStore.getStore(store) {
    getData();
  }

  static final changed = ValueNotifier<(String, dynamic)?>(null);

  final DataStore store;
  final String name;
  Map<String, dynamic>? _data;

  void getData() {
    _data = store.getData(name) ?? {};
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
    store.setData(name, _data);
    if (notify) {
      changed.value = ('${store.store}.$name.$key', value);
      notifyListeners();
    }
  }
}
