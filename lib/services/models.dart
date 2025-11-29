import 'cloud_service.dart';

class Group {
  final String id;
  final String group;
  final String name;
  final int number;
  final int total;
  final DateTime update;

  Group(RowData data)
    : id = (data['\$id'] ?? '') as String,
      group = (data['group'] ?? 'Null') as String,
      name = (data['name'] ?? 'Null') as String,
      number = (data['num'] ?? 0) as int,
      total = (data['total'] ?? 0) as int,
      update = DateTime.parse(
        data['update'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal();
}

class Thread {
  final String id;
  final String group;
  final String subject;
  final String sender;
  final double hot;
  final int total;
  final DateTime latest;
  final DateTime date;
  final int number;
  final String msgid;

  Thread(RowData data)
    : id = (data['\$id'] ?? '') as String,
      group = (data['group'] ?? '') as String,
      subject = ((data['subject'] ?? '') as String).trim(),
      sender = ((data['sender'] ?? '') as String).trim(),
      hot = ((data['hot'] ?? 0.0) as num).toDouble(),
      total = (data['total'] ?? 1) as int,
      latest = DateTime.parse(
        data['latest'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      date = DateTime.parse(
        data['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      number = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String;
}

class Post {
  final String id;
  final String thread;
  final String sender;
  final String? text;
  final bool html;
  final String? textFile;
  final List<String> files;
  final DateTime date;
  final int number;
  final String msgid;
  final List<String> ref;

  Post(RowData data)
    : id = (data['\$id'] ?? '') as String,
      thread = (data['thread'] ?? '') as String,
      sender = ((data['sender'] ?? '') as String).trim(),
      text = (data['text'] as String?),
      html = (data['html'] ?? false) as bool,
      textFile = data['textfile'] as String?,
      files = ((data['files'] ?? []) as List).map((e) => e as String).toList(),
      date = DateTime.parse(
        data['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
      ).toLocal(),
      number = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String,
      ref = ((data['ref'] ?? []) as List).map((e) => e as String).toList();

  Post.from(Post post)
    : id = post.id,
      thread = post.thread,
      sender = post.sender,
      text = post.text,
      html = post.html,
      textFile = post.textFile,
      files = post.files,
      date = post.date,
      number = post.number,
      msgid = post.msgid,
      ref = post.ref;
}
