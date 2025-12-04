import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import "package:universal_html/html.dart" as html;

class DataStore extends ChangeNotifier {
  DataStore._(this.name);

  static const String app = 'elaine';
  static final Map<String, DataStore> _store = {};

  final String name;

  String get path => p.join(app, name);

  static DataStore store(String name) {
    return _store.putIfAbsent(name, () => DataStore._(name));
  }

  static Iterable<String> list() {
    return html.window.localStorage.keys
        .where((e) => p.split(e).firstOrNull == app)
        .map((e) => p.split(e).skip(1).firstOrNull)
        .nonNulls;
  }

  Iterable<String> datas() {
    return html.window.localStorage.keys
        .where((e) => p.split(e).firstOrNull == app)
        .where((e) => p.split(e).skip(1).firstOrNull == name)
        .map((e) => p.split(e).skip(2).firstOrNull)
        .nonNulls;
  }

  void remove(String data) {
    final path = p.join(app, name, data);
    html.window.localStorage.remove(path);
  }

  String? get(String data) {
    final path = p.join(app, name, data);
    return html.window.localStorage[path];
  }

  void set(String data, dynamic value, {bool notify = true}) {
    if (value == get(data)) return;
    final path = p.join(app, name, data);
    html.window.localStorage[path] = value;
    if (notify) notifyListeners();
  }
}

class DataValue extends ChangeNotifier {
  DataValue(String store, this.name) : store = DataStore.store(store) {
    getData();
  }

  final DataStore store;
  final String name;
  Map<String, dynamic>? _data;

  void getData() {
    final data = store.get(name);
    _data = data == null ? {} : json.decode(data);
  }

  T? get<T>(String key) {
    return _data?[key] as T?;
  }

  void set(String key, dynamic value, {bool notify = true}) {
    if (value == get(key)) return;
    getData();
    _data?[key] = value;
    store.set(name, json.encode(_data ?? {}));
    if (notify) notifyListeners();
  }
}
