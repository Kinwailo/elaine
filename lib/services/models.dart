import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cloud_service.dart';

class GroupData {
  final String id;
  final String group;
  final String name;
  final int num;
  final int total;
  final DateTime update;

  GroupData(RowData data)
    : id = (data['\$id'] ?? '') as String,
      group = (data['group'] ?? 'Null') as String,
      name = (data['name'] ?? 'Null') as String,
      num = (data['num'] ?? 0) as int,
      total = (data['total'] ?? 0) as int,
      update = DateTime.parse(
        data['update'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal();
}

class ThreadData {
  final String id;
  final String group;
  final String subject;
  final String sender;
  final double hot;
  final int total;
  final DateTime latest;
  final DateTime date;
  final int num;
  final String msgid;

  ThreadData(RowData data)
    : id = (data['\$id'] ?? '') as String,
      group = (data['group'] ?? '') as String,
      subject = ((data['subject'] ?? 'Null') as String).trim(),
      sender = ((data['sender'] ?? 'Null') as String).trim(),
      hot = (data['hot'] ?? 0.0) as double,
      total = (data['total'] ?? 1) as int,
      latest = DateTime.parse(
        data['latest'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      date = DateTime.parse(
        data['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      num = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String;
}

class PostData {
  final String id;
  final String thread;
  final String sender;
  final String? text;
  final bool html;
  final String? textFile;
  final List<String> files;
  final DateTime date;
  final int num;
  final String msgid;
  final List<String> ref;

  PostData(RowData data)
    : id = (data['\$id'] ?? '') as String,
      thread = (data['thread'] ?? '') as String,
      sender = ((data['sender'] ?? 'Null') as String).trim(),
      text = data['text'] as String?,
      html = (data['html'] ?? false) as bool,
      textFile = data['textFile'] as String?,
      files = ((data['files'] ?? []) as List).map((e) => e as String).toList(),
      date = DateTime.parse(
        data['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      num = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String,
      ref = ((data['ref'] ?? []) as List).map((e) => e as String).toList();
}

abstract class ThreadDataListenable extends Listenable {
  const ThreadDataListenable();
  ThreadData get value;

  String get id;
  String get group;
  String get subject;
  String get sender;
  double get hot;
  int get total;
  DateTime get latest;
  DateTime get date;
  int get num;
  String get msgid;
}

class ThreadDataNotifier extends ValueNotifier<ThreadData>
    implements ThreadDataListenable {
  ThreadDataNotifier(super.value);

  @override
  String get id => value.id;
  @override
  String get group => value.group;
  @override
  String get subject => value.subject;
  @override
  String get sender => value.sender;
  @override
  double get hot => value.hot;
  @override
  int get total => value.total;
  @override
  DateTime get latest => value.latest;
  @override
  DateTime get date => value.date;
  @override
  int get num => value.num;
  @override
  String get msgid => value.msgid;
}

abstract class PostDataListenable extends Listenable {
  const PostDataListenable();
  PostData get value;

  String get id;
  String get thread;
  String get sender;
  String? get text;
  bool get html;
  String? get textFile;
  List<String> get files;
  DateTime get date;
  int get num;
  String get msgid;
  List<String> get ref;
}

class PostDataNotifier extends ValueNotifier<PostData>
    implements PostDataListenable {
  PostDataNotifier(super.value);

  @override
  String get id => value.id;
  @override
  String get thread => value.thread;
  @override
  String get sender => value.sender;
  @override
  String? get text => value.text;
  @override
  bool get html => value.html;
  @override
  String? get textFile => value.textFile;
  @override
  List<String> get files => value.files;
  @override
  DateTime get date => value.date;
  @override
  int get num => value.num;
  @override
  String get msgid => value.msgid;
  @override
  List<String> get ref => value.ref;
}
