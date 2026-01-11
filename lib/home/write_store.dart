import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';

import '../app/const.dart';
import '../services/cloud_service.dart';
import '../services/data_store.dart';
import '../settings/settings_data.dart';
import 'group_store.dart';
import 'post_store.dart';

class ImageData {
  ImageData(this.filename, this.fileData) {
    decoder = img.findDecoderForNamedImage(filename);
    info = decoder?.startDecode(fileData);
    imageData = fileData;
  }
  String filename;
  Uint8List fileData = Uint8List(0);

  img.Decoder? decoder;
  img.DecodeInfo? info;
  img.Image? image;

  int scale = WriteStore.scaleList.length - 1;
  bool original = true;
  bool hqResize = false;
  Uint8List imageData = Uint8List(0);
}

class WriteStore {
  Map<String, dynamic>? identity;
  String name = '';
  String email = '';
  String subject = '';
  String body = '';
  String signature = '';
  String quote = '';

  bool enableSignature = true;
  bool enableQuote = true;

  String rawQuote = '';
  List<String> references = [];

  String? error;
  bool succuss = false;

  final postData = ValueNotifier<PostData?>(null);
  final images = ValueNotifier(<ImageData>[]);
  final selectedFile = ValueNotifier<ImageData?>(null);
  final resizing = ValueNotifier(false);
  final sendable = ValueNotifier(false);
  final sending = ValueNotifier(false);

  static const scaleList = [0.16, 0.25, 0.33, 0.50, 0.66, 0.75, 0.90, 1.00];

  GroupData? _group;

  void create(PostData? post) {
    if (post == null) {
      final groups = Modular.get<GroupStore>();
      _group = groups.selected.value;
    } else {
      _group = post.thread?.group;
    }
    postData.value = post;
    succuss = false;
    error = null;

    final ids = getSetting<List>('group', 'identities');
    final gid = getSetting<Map>('group', 'groupIdentitiy');
    if (gid.containsKey(_group?.data.group ?? '')) {
      identity = ids.firstWhereOrNull(
        (e) => e['name'] == gid[_group!.data.group],
      );
    }
    updateSendable();

    var re = RegExp(r'^(Re: ?)*');
    var text = post?.thread?.data.subject ?? '';
    if (text.isNotEmpty) text = 'Re: ${text.replaceAll(re, '')}';
    subject = text;

    rawQuote = const LineSplitter()
        .convert(post?.getText() ?? '')
        .map((e) => '> $e')
        .join('\n');
    quote = rawQuote.length < getChop()
        ? rawQuote
        : '${rawQuote.substring(0, getChop())}...';
    references = post == null ? [] : [...post.data.ref, post.data.msgid];
  }

  String getTitle() {
    if (postData.value != null) {
      return '$replyPostText$colonText${postData.value?.thread?.data.subject ?? ''}';
    }
    final group = _group?.data.name ?? '';
    return '$newPostText$colonText$group';
  }

  void updateSendable() {
    final ids = getSetting<List>('group', 'identities');
    final nameExist = ids.any((e) => e['name'] == name);
    sendable.value =
        !succuss &&
        (identity != null ||
            !nameExist && name.isNotEmpty && email.isNotEmpty) &&
        subject.isNotEmpty &&
        (body.isNotEmpty || images.value.isNotEmpty);
  }

  String quoteAll() {
    quote = rawQuote;
    return quote;
  }

  int getChop() {
    final dv = DataValue('settings', 'write');
    return dv.get<int>('chopQuote') ?? 500;
  }

  bool needChop() {
    return rawQuote.length > getChop();
  }

  int charChopped() {
    return rawQuote.length - getChop();
  }

  Future<void> pickFiles() async {
    var result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      images.value = [
        ...images.value,
        ...result.files.map((e) => ImageData(e.name, e.bytes ?? Uint8List(0))),
      ];
      selectedFile.value ??= images.value.first;
    }
  }

  void addFile(String filename, Uint8List data) {
    images.value = [...images.value, ImageData(filename, data)];
    selectedFile.value ??= images.value.first;
  }

  void removeFile(ImageData? image) {
    if (image == null) return;
    images.value = images.value.where((e) => e != image).toList();
    if (selectedFile.value == image) {
      selectedFile.value = images.value.firstOrNull;
    }
  }

  Future<void> setImageScale(
    ImageData image,
    int scale,
    bool original,
    bool hqResize,
  ) async {
    image.scale = scale;
    image.original = original;
    image.hqResize = hqResize;

    img.Command? cmd;

    if (original) {
      image.imageData = image.fileData;
    } else {
      if (image.decoder == null || image.info == null) return;

      image.image ??= image.decoder!.decodeFrame(0);
      cmd = img.Command()
        ..image(image.image!)
        ..copyResize(
          width: (image.info!.width * scaleList[scale]).toInt(),
          interpolation: hqResize
              ? img.Interpolation.cubic
              : img.Interpolation.linear,
        )
        ..encodeJpg(quality: 85);
    }
    images.value = [...images.value];

    if (cmd != null) {
      resizing.value = true;
      image.imageData = await cmd.getBytesThread() ?? Uint8List(0);
      resizing.value = false;
    }
  }

  Future<void> send() async {
    error = null;
    sending.value = true;

    final n = identity == null ? name : identity!['name'];
    final e = identity == null ? email : identity!['email'];
    final s = identity == null ? signature : identity!['signature'];

    var content = body;
    if (enableSignature && s.isNotEmpty) {
      content += '\n\n--\n$s';
    }
    if (enableQuote && quote.isNotEmpty) {
      content +=
          '\n\n${postData.value?.data.sender ?? quoteSomeoneText}$quoteWriteText$colonText\n$quote';
    }
    if (images.value.isNotEmpty) content += '\n';

    final group = _group?.data.group;
    if (group == null) {
      error = '$writeErrorText$colonText$writeNoGroupText';
      sending.value = false;
      return;
    }

    final sendData = {
      'From': '$n <$e>',
      'Subject': subject,
      'Newsgroups': group,
      'References': references,
      'Content': content,
      'files': images.value
          .map((e) => {'bytes': base64Encode(e.imageData), 'name': e.filename})
          .toList(),
    };
    final cloud = Modular.get<CloudService>();
    final res = await cloud.createPost(sendData);
    if (res == null) {
      error = '$writeErrorText$colonText$writeResErrorText';
    } else if (res.containsKey('error')) {
      error = '$writeErrorText$colonText${res['error']}';
    } else {
      succuss = true;
      if (identity == null) {
        setSetting('group', 'identities', [
          ...getSetting<List>('group', 'identities'),
          {'name': name, 'email': email, 'signature': signature},
        ]);
      }
      setSetting('group', 'groupIdentitiy', {
        ...getSetting<Map>('group', 'groupIdentitiy'),
        group: n,
      });
    }
    sending.value = false;
    updateSendable();
  }
}
