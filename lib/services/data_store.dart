import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import "package:universal_html/html.dart" as html;

class DataStore extends ChangeNotifier {
  DataStore._(this.name) {
    _load();
  }

  static const String app = 'elaine';
  static final Map<String, DataStore> _store = {};

  final String name;
  final Map<String, dynamic> _data = {};
  bool _changed = false;

  String get path => join(app, name);

  static DataStore store(String name) {
    return _store.putIfAbsent(name, () => DataStore._(name));
  }

  static List<String> list() {
    return html.window.localStorage.keys
        .where((e) => dirname(e) == app)
        .map((e) => basenameWithoutExtension(e))
        .toList();
  }

  Iterable<String> keys() {
    return _data.keys;
  }

  void remove(String key) {
    _data.remove(key);
  }

  T? get<T>(String key) {
    return _data[key] as T?;
  }

  void set(String key, dynamic value, {bool notify = true}) {
    if (value == get(key)) return;
    _changed = true;
    _data[key] = value;
    if (notify) notifyListeners();
  }

  void _load() {
    final text = html.window.localStorage[withoutExtension(path)];
    try {
      if (text != null) _data.addAll(json.decode(text));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void save() {
    if (_changed) {
      _changed = false;
      final text = json.encode(_data);
      html.window.localStorage[withoutExtension(path)] = text;
    }
  }

  void delete() {
    _data.clear();
    _store.remove(path);
    html.window.localStorage.remove(withoutExtension(path));
    notifyListeners();
  }
}
