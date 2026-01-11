import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../settings/settings_data.dart';
import 'write_store.dart';

class WriteDialog extends HookWidget {
  const WriteDialog({super.key});

  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) {
        return WriteDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).appBarTheme;
    final write = Modular.get<WriteStore>();
    final sendable =
        write.sendable.value && !write.resizing.value && !write.sending.value;
    final showState = write.sending.value || write.error != null;
    final messengerKey = useMemoized(() => GlobalKey<ScaffoldMessengerState>());
    final scrollController = useScrollController();
    useListenable(write.sendable.postFrame);
    useListenable(write.resizing);
    useListenable(write.sending);
    useValueChanged(showState && write.error == null, (_, void _) {
      final text = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(write.error == null ? writeSuccessText : write.error!),
      );
      final content = write.error == null
          ? write.sending.value
                ? LinearProgressIndicator(minHeight: 4)
                : text
          : text;
      messengerKey.currentState?.clearMaterialBanners();
      messengerKey.currentState?.showMaterialBanner(
        MaterialBanner(
          backgroundColor: theme.backgroundColor,
          padding: EdgeInsets.all(0),
          margin: EdgeInsets.all(0),
          contentTextStyle: pinnedTextStyle.merge(errorTextStyle),
          content: content,
          actions: <Widget>[SizedBox.shrink()],
          forceActionsBelow: true,
          minActionBarHeight: 0,
        ),
      );
      if (write.error == null && !write.sending.value) {
        Future.delayed(
          1.seconds,
        ).then((_) => context.mounted ? Navigator.maybePop(context) : ());
      }
    });
    return Dialog(
      insetPadding: EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: 600, maxWidth: 800),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadiusGeometry.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(8),
        child: ScaffoldMessenger(
          key: messengerKey,
          child: PointerInterceptor(
            child: Scaffold(
              backgroundColor: colorScheme.surfaceContainerHigh,
              appBar: AppBar(
                toolbarHeight: kToolbarHeight - 12,
                automaticallyImplyLeading: false,
                title: Text(write.getTitle()),
                actions: [
                  CloseButton(
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1),
                ),
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Opacity(
                  opacity: !sendable ? 0.3 : 1.0,
                  child: FloatingActionButton.small(
                    onPressed: !sendable ? null : write.send,
                    child: Icon(Icons.send),
                  ),
                ),
              ),
              body: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(top: 4, left: 4, right: 12 + 4),
                      sliver: SuperSliverList.list(
                        children: [
                          const WriteIdentity(),
                          if (write.postData.value == null)
                            const WriteSubject(),
                          const WriteContent(),
                          const WriteSignature(),
                          if (write.postData.value != null) const WriteQuote(),
                          const WriteAttachment(),
                          const SizedBox(height: 66),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WriteIdentity extends HookWidget {
  const WriteIdentity({super.key});

  @override
  Widget build(BuildContext context) {
    final write = Modular.get<WriteStore>();
    final name = useTextEditingController(text: write.name);
    final email = useTextEditingController(text: write.email);
    final identity = useState(write.identity);
    final ids = getSetting<List>('group', 'identities');
    final nameExist = ids.any((e) => e['name'] == name.text);
    final empty = name.text.isEmpty && email.text.isEmpty;
    useListenable(name);
    useListenable(email);
    useValueChanged(empty, (_, void _) => write.updateSendable());
    useValueChanged(nameExist, (_, void _) => write.updateSendable());
    useValueChanged(identity.value, (_, void _) => write.updateSendable());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            DropdownButton(
              isExpanded: true,
              value: identity.value,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(enterIdentityText),
                ),
                ...ids.cast<Map<String, dynamic>>().map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text('${e['name']} <${e['email']}>'),
                  ),
                ),
              ],
              onChanged: (newValue) {
                identity.value = write.identity = newValue;
              },
            ),
            if (write.identity == null) ...[
              TextField(
                style: mainTextStyle,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  labelText: nameText,
                  errorText: nameExist
                      ? identityExist
                      : name.text.isNotEmpty
                      ? null
                      : nameText + emptyInputText,
                ),
                controller: name,
                onChanged: (value) => write.name = name.text,
              ),
              TextField(
                style: mainTextStyle,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  labelText: emailText,
                  errorText: email.text.isNotEmpty
                      ? null
                      : emailText + emptyInputText,
                ),
                controller: email,
                onChanged: (value) => write.email = email.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WriteSubject extends HookWidget {
  const WriteSubject({super.key});

  @override
  Widget build(BuildContext context) {
    final write = Modular.get<WriteStore>();
    final subject = useTextEditingController(text: write.subject);
    useListenable(subject);
    useValueChanged(
      subject.text.isEmpty,
      (_, void _) => write.updateSendable(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          style: mainTextStyle,
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            labelText: subjectText,
            errorText: subject.text.isNotEmpty
                ? null
                : subjectText + emptyInputText,
          ),
          controller: subject,
          onChanged: (value) => write.subject = subject.text,
        ),
      ),
    );
  }
}

class WriteContent extends HookWidget {
  const WriteContent({super.key});

  @override
  Widget build(BuildContext context) {
    final write = Modular.get<WriteStore>();
    final body = useTextEditingController(text: write.body);
    final empty = body.text.isEmpty && write.images.value.isEmpty;
    useListenable(body);
    useListenable(write.images);
    useValueChanged(empty, (_, void _) => write.updateSendable());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            TextField(
              style: mainTextStyle,
              maxLines: null,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 4,
                ),
                labelText: bodyText,
                errorText: !empty
                    ? null
                    : bodyText + orText + attachmentText + emptyInputText,
              ),
              controller: body,
              onChanged: (value) => write.body = body.text,
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                splashRadius: 20,
                icon: const Icon(Icons.clear),
                onPressed: body.text.isEmpty ? null : body.clear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WriteSignature extends HookWidget {
  const WriteSignature({super.key});

  @override
  Widget build(BuildContext context) {
    final write = Modular.get<WriteStore>();
    final signature = useTextEditingController(text: write.signature);
    final enable = useState(write.enableSignature);
    useListenable(signature);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            TextField(
              style: mainTextStyle,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: signatureText,
                isDense: true,
                filled: false,
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 4,
                ),
              ),
              controller: signature,
              onChanged: (value) => write.signature = signature.text,
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Checkbox(
                value: write.enableSignature,
                onChanged: (v) => enable.value = write.enableSignature = v!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WriteQuote extends HookWidget {
  const WriteQuote({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    final write = Modular.get<WriteStore>();
    final quote = useTextEditingController(text: write.quote);
    final all = useState(false);
    useListenable(quote);
    void quoteListener() => all.value = true;
    useEffect(() {
      quote.addListener(quoteListener);
      return () => quote.removeListener(quoteListener);
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  style: mainTextStyle,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: quoteText,
                    isDense: true,
                    filled: false,
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.only(
                      left: 16,
                      top: 16,
                      right: 16,
                      bottom: 4,
                    ),
                  ),
                  controller: quote,
                  onChanged: (value) => write.quote = quote.text,
                ),
                if (!all.value && write.needChop())
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: RichText(
                      text: TextSpan(
                        text: '${write.charChopped()}$charChoppedText ',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: quoteAllText,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => quote.text = write.quoteAll(),
                          ),
                          const TextSpan(text: ' '),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Checkbox(
                value: write.enableQuote,
                onChanged: (v) => write.enableQuote = v!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WriteAttachment extends HookWidget {
  const WriteAttachment({super.key});

  @override
  Widget build(BuildContext context) {
    final write = Modular.get<WriteStore>();
    var selected = write.selectedFile.value;

    final scale = useState(WriteStore.scaleList.length - 1);
    final original = useState(true);
    final hqResize = useState(false);

    useListenable(write.images);
    useListenable(write.selectedFile);
    useListenable(write.resizing);
    useValueChanged(selected, (_, void _) {
      scale.value = selected?.scale ?? WriteStore.scaleList.length - 1;
      original.value = selected?.original ?? true;
      hqResize.value = selected?.hqResize ?? false;
    });
    useValueChanged(
      write.images.value.isEmpty,
      (_, void _) => write.updateSendable,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: write.images.value
                        .map((e) => WriteFile(e))
                        .toList(),
                  ),
                ),
                if (write.images.value.isNotEmpty) const Divider(),
                if (selected != null)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...WriteStore.scaleList.mapIndexed(
                        (i, e) => ChoiceChip(
                          showCheckmark: false,
                          label: Text('${(e * 100).toStringAsFixed(0)}%'),
                          padding: const EdgeInsets.all(0),
                          selected: !original.value && scale.value == i,
                          onSelected: (v) {
                            if (!v) return;
                            if (write.resizing.value) return;
                            if (original.value || scale.value != i) {
                              scale.value = i;
                              original.value = false;
                              write.setImageScale(
                                selected,
                                i,
                                false,
                                hqResize.value,
                              );
                            }
                          },
                        ),
                      ),
                      ChoiceChip(
                        showCheckmark: false,
                        label: const Text(originalImageText),
                        padding: const EdgeInsets.all(0),
                        selected: original.value,
                        onSelected: (v) {
                          if (!v) return;
                          if (write.resizing.value) return;
                          if (original.value != v) {
                            original.value = v;
                            write.setImageScale(
                              selected,
                              scale.value,
                              true,
                              hqResize.value,
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        showCheckmark: false,
                        label: const Text(hqImageText),
                        padding: const EdgeInsets.all(0),
                        selected: hqResize.value,
                        onSelected: (v) {
                          if (write.resizing.value) return;
                          hqResize.value = v;
                          write.setImageScale(
                            selected,
                            scale.value,
                            original.value,
                            v,
                          );
                        },
                      ),
                      ActionChip(
                        label: const Text(removeImageText),
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          if (write.resizing.value) return;
                          write.removeFile(selected);
                        },
                      ),
                    ],
                  ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                splashRadius: 20,
                icon: const Icon(Icons.attach_file),
                onPressed: write.pickFiles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WriteFile extends HookWidget {
  const WriteFile(this.image, {super.key});

  final ImageData image;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    final write = Modular.get<WriteStore>();

    var scale = WriteStore.scaleList[image.scale];
    var width = image.info?.width ?? 0;
    var height = image.info?.height ?? 0;
    var size = image.imageData.lengthInBytes;

    var widthText = (width * scale).toStringAsFixed(0);
    var heightText = (height * scale).toStringAsFixed(0);
    var sizeText = size > (1024 * 1024)
        ? '${(size / (1024 * 1024)).toStringAsFixed(2)}M'
        : size > 1024
        ? '${(size / 1024).toStringAsFixed(2)}k'
        : size;

    useListenable(write.resizing);
    return Container(
      height: 100,
      constraints: BoxConstraints(maxWidth: max(100, width * 100 / height)),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(
          style: write.selectedFile.value == image
              ? BorderStyle.solid
              : BorderStyle.none,
          color: colorScheme.primary.withValues(alpha: 0.8),
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Material(
          child: IgnorePointer(
            ignoring: write.resizing.value,
            child: InkWell(
              onTap: () => write.selectedFile.value = image,
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Center(
                    child: Ink.image(
                      image: MemoryImage(image.imageData),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Ink(
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          child:
                              write.resizing.value &&
                                  write.selectedFile.value == image
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: SizedBox.square(
                                      dimension: 30,
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('$widthText x $heightText'),
                                    Text('$sizeText'),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
