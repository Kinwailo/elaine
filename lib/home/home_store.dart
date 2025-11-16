import 'package:flutter/foundation.dart';

class HomeStore {
  final currentThreadTile = ValueNotifier<int?>(null);

  int? getThreadTile(int? number) {
    if (currentThreadTile.value == null) {
      currentThreadTile.value = number;
    }
    return currentThreadTile.value;
  }

  int? updateThreadTile(int? number) {
    if (number != null) {
      currentThreadTile.value = number;
    }
    return currentThreadTile.value;
  }
}
