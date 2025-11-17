import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart' hide TextDirection;

final syncBodyText = '文章正從新聞組同步中…';

final mainTextStyle = TextStyle(fontSize: 18);
final subTextStyle = TextStyle(color: Colors.grey, fontSize: 14);
final senderTextStyle = TextStyle(color: Colors.blueAccent, fontSize: 14);

int get hotRef => DateTime.now().difference(DateTime(2025, 10, 1)).inSeconds;

ValueNotifier<T?> futureToNotifier<T>(Future<T> future, {T? initialValue}) {
  final notifier = ValueNotifier<T?>(initialValue);
  future.then((value) {
    notifier.value = value;
  });
  return notifier;
}

extension DateCasting on DateTime {
  String get format => DateFormat('yyyy-MM-dd HH:mm').format(this);
  String get relative =>
      GetTimeAgo.parse(this, locale: 'zh_tr', pattern: 'yyyy-MM-dd HH:mm');
}

Size estimateTextSize(
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: null,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return textPainter.size;
}
