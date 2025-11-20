import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart' hide TextDirection;

const syncBodyText = '文章正從新聞組同步中…';

const mainTextStyle = TextStyle(fontSize: 18);
const subTextStyle = TextStyle(color: Colors.grey, fontSize: 14);
const senderTextStyle = TextStyle(color: Colors.blueAccent, fontSize: 14);

int get hotRef => DateTime.now().difference(DateTime(2025, 10, 1)).inSeconds;

ValueNotifier<T?> futureToNotifier<T>(Future<T> future, {T? initialValue}) {
  final notifier = ValueNotifier<T?>(initialValue);
  future.then((value) {
    notifier.value = value;
  });
  return notifier;
}

Future<ui.Size> getImageSize(Uint8List data) async {
  final completer = Completer<ui.Size>();
  final image = Image.memory(data);
  image.image
      .resolve(ImageConfiguration())
      .addListener(
        ImageStreamListener(
          (i, _) => completer.complete(
            ui.Size(i.image.width.toDouble(), i.image.height.toDouble()),
          ),
        ),
      );
  return completer.future;
}

extension DateCasting on DateTime {
  String get format => DateFormat('yyyy-MM-dd HH:mm').format(this);
  String get relative =>
      GetTimeAgo.parse(this, locale: 'zh_tr', pattern: 'yyyy-MM-dd HH:mm');
}

double estimateTextHeight(
  String text,
  TextStyle style, {
  int? maxLines,
  double maxWidth = double.infinity,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return textPainter.height + 1;
}

abstract class ListListenable<T> extends Listenable {
  const ListListenable();
  List<T> get value;
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;
  T operator [](int index);
}

class ListNotifier<T> extends ValueNotifier<List<T>>
    implements ListListenable<T> {
  ListNotifier(super.value);

  @override
  int get length => value.length;
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  T operator [](int index) {
    if (index >= 0 && index < value.length) {
      return value[index];
    }
    throw RangeError.index(index, value, 'index', null, value.length);
  }

  void clear() {
    value = [];
  }

  void prepend(Iterable<T> items) {
    value = [...items, ...value];
  }

  void append(Iterable<T> items) {
    value = [...value, ...items];
  }
}

abstract class MapListenable<K, V> extends Listenable {
  const MapListenable();
  Map<K, V> get value;
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;
  V? operator [](Object? key);
}

class MapNotifier<K, V> extends ValueNotifier<Map<K, V>>
    implements MapListenable<K, V> {
  MapNotifier(super.value);

  @override
  int get length => value.length;
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  V? operator [](Object? key) {
    if (key is K) {
      return value[key];
    }
    return null;
  }

  void clear() {
    value = {};
  }

  void addAll(Map<K, V> items) {
    value = {...value, ...items};
  }
}
