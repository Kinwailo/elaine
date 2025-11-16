import 'package:flutter/foundation.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';

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
