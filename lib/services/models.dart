import '../app/utils.dart';
import 'cloud_service.dart';

class Group {
  final String id;
  final int order;
  final String group;
  final String name;
  final int number;
  final int total;
  final DateTime update;

  Group(RowData data)
    : id = (data[r'$id'] ?? '') as String,
      order = (data['order'] ?? 0) as int,
      group = (data['group'] ?? 'Null') as String,
      name = (data['name'] ?? 'Null') as String,
      number = (data['num'] ?? 0) as int,
      total = (data['total'] ?? 0) as int,
      update = parseDateTime(data['update']);
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
  final DateTime create;
  final DateTime update;

  Thread(RowData data)
    : id = (data[r'$id'] ?? '') as String,
      group = (data['group'] ?? '') as String,
      subject = ((data['subject'] ?? '') as String).trim(),
      sender = ((data['sender'] ?? '') as String).trim(),
      hot = ((data['hot'] ?? 0.0) as num).toDouble(),
      total = (data['total'] ?? 1) as int,
      latest = parseDateTime(data['latest']),
      date = parseDateTime(data['date']),
      number = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String,
      create = parseDateTime(data[r'$createdAt']),
      update = parseDateTime(data[r'$updatedAt']);
}

class Post {
  final String id;
  final String thread;
  final String sender;
  final int index;
  final int total;
  final String? text;
  final bool html;
  final String? textFile;
  final List<String> files;
  final DateTime date;
  final int number;
  final String msgid;
  final String quote;
  final List<String> ref;
  final DateTime create;
  final DateTime update;

  Post(RowData data)
    : id = (data[r'$id'] ?? '') as String,
      thread = (data['thread'] ?? '') as String,
      sender = ((data['sender'] ?? '') as String).trim(),
      index = (data['index'] ?? 0) as int,
      total = (data['total'] ?? 0) as int,
      text = (data['text'] as String?),
      html = (data['html'] ?? false) as bool,
      textFile = data['textfile'] as String?,
      files = ((data['files'] ?? []) as List).map((e) => e as String).toList(),
      date = parseDateTime(data['date']),
      number = (data['num'] ?? 0) as int,
      msgid = (data['msgid'] ?? '') as String,
      quote = (data['quote'] ?? '') as String,
      ref = ((data['ref'] ?? []) as List).map((e) => e as String).toList(),
      create = parseDateTime(data[r'$createdAt']),
      update = parseDateTime(data[r'$updatedAt']);

  Post.from(Post post)
    : id = post.id,
      thread = post.thread,
      sender = post.sender,
      index = post.index,
      total = post.total,
      text = post.text,
      html = post.html,
      textFile = post.textFile,
      files = post.files,
      date = post.date,
      number = post.number,
      msgid = post.msgid,
      quote = post.quote,
      ref = post.ref,
      create = post.create,
      update = post.update;
}
