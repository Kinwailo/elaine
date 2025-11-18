import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:elaine/services/models.dart';
import 'package:flutter/foundation.dart';

typedef QuoteNotifier = ValueNotifier<PostData?>;
typedef FileNotifier = ValueNotifier<Uint8List?>;
typedef SizeNotifier = ValueNotifier<Size?>;

class PostTileData {
  final quote = QuoteNotifier(null);
  final files = <FileNotifier>[];
  final sizes = <SizeNotifier>[];
}

class HomeStore {
  final _postTileDatas = <int, PostTileData>{};

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

  PostTileData getPostTileData(int index) {
    return _postTileDatas.putIfAbsent(index, () => PostTileData());
  }

  void setPostQuote(int index, Future<PostData?> quote) {
    final data = getPostTileData(index);
    quote.then((value) {
      data.quote.value = value;
    });
  }

  QuoteNotifier getPostQuote(int index) {
    return getPostTileData(index).quote;
  }

  Listenable get allPostQuoteListenable =>
      Listenable.merge(_postTileDatas.values.map((e) => e.quote));

  void setPostFiles(int index, List<Future<Uint8List>> files) {
    final data = getPostTileData(index);
    data.files
      ..clear()
      ..addAll(List.filled(files.length, FileNotifier(null)));
    var zipped = IterableZip([data.files, files]);
    for (var pair in zipped) {
      (pair[1] as Future).then((value) {
        (pair[0] as FileNotifier).value = value;
      });
    }
  }

  List<FileNotifier> getPostFiles(int index) {
    return getPostTileData(index).files;
  }

  Listenable get allPostFilesListenable => Listenable.merge(
    _postTileDatas.values.map((e) => e.files).expand((e) => e),
  );
}
