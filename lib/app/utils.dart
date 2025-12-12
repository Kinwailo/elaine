import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'const.dart';

int get hotRef => DateTime.now().difference(DateTime(2025, 10, 1)).inSeconds;

ValueNotifier<T?> futureToNotifier<T>(Future<T> future, {T? initialValue}) {
  final notifier = ValueNotifier<T?>(initialValue);
  future.then((value) {
    notifier.value = value;
  });
  return notifier;
}

Future<Size> getImageSize(Uint8List data) async {
  final completer = Completer<Size>();
  final image = Image.memory(data);
  image.image
      .resolve(ImageConfiguration())
      .addListener(
        ImageStreamListener(
          (i, _) => completer.complete(
            Size(i.image.width.toDouble(), i.image.height.toDouble()),
          ),
        ),
      );
  return completer.future;
}

DateTime parseDateTime(String? s) {
  return DateTime.parse(s ?? refDateTime.toString()).toLocal();
}

extension StringFormatter on String {
  String format(List<dynamic> values) =>
      values.fold(this, (v, e) => v.replaceFirst('%s', e.toString()));
}

extension DateCasting on DateTime {
  String get format => DateFormat('yyyy-MM-dd HH:mm').format(this);
  String get relative =>
      GetTimeAgo.parse(this, locale: 'zh_tr', pattern: 'yyyy-MM-dd HH:mm');
}

extension SeparatorExtension<T> on Iterable<T> {
  List<T> separator(T item) =>
      isEmpty ? [] : skip(1).fold([first], (v, e) => v..addAll([item, e]));
}

final textHeightCache = <(String, TextStyle, int?, double), double>{};

double estimateTextHeight(
  String text,
  TextStyle style, {
  int? maxLines,
  double maxWidth = double.infinity,
}) {
  final height = textHeightCache[(text, style, maxLines, maxWidth)];
  if (height != null) return height;
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return textHeightCache.putIfAbsent((
    text,
    style,
    maxLines,
    maxWidth,
  ), () => textPainter.height + 1);
}

double estimateWrappedHeight(
  Iterable<double> widths,
  double itemHeight,
  double maxWidth,
) {
  return widths.fold(Size(0, itemHeight), (v, e) {
    return v.width + e <= maxWidth
        ? Size(v.width + e, v.height)
        : Size(e, v.height + itemHeight);
  }).height;
}

extension ListenableExtension on Listenable {
  Listenable get postFrame => PostFrameListenable(this);
}

class PostFrameListenable extends Listenable with ChangeNotifier {
  PostFrameListenable(this.listenable) {
    listenable.addListener(listener);
  }

  final Listenable listenable;

  void listener() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  @override
  void dispose() {
    removeListener(listener);
    super.dispose();
  }
}

extension ValueListenableExtension<E> on ValueListenable<E> {
  SelectedListenable<T, E> select<T>(T Function(E) selector) =>
      SelectedListenable<T, E>(this, selector);
}

class SelectedListenable<T, E> extends ValueListenable<T> with ChangeNotifier {
  SelectedListenable(this.listenable, this.selector)
    : _value = selector(listenable.value) {
    listenable.addListener(listener);
  }

  final ValueListenable<E> listenable;
  final T Function(E) selector;
  T _value;

  void listener() {
    final v = selector(listenable.value);
    if (_value == v) return;
    _value = v;
    notifyListeners();
  }

  @override
  void dispose() {
    removeListener(listener);
    super.dispose();
  }

  @override
  T get value => _value;
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
