import 'dart:math';

import 'package:collection/collection.dart';
import 'package:elaine/app/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';
import '../services/data_store.dart';
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
    final write = Modular.get<WriteStore>();
    final scrollController = useScrollController();
    useListenable(write.sendable.postFrame);
    return Dialog(
      insetPadding: EdgeInsets.all(8),
      constraints: BoxConstraints(
        minWidth: 600,
        maxWidth: 800,
        // minHeight: double.infinity,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadiusGeometry.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(8),
        child: Scaffold(
          backgroundColor: colorScheme.surfaceContainerHigh,
          appBar: AppBar(
            toolbarHeight: kToolbarHeight - 12,
            title: Text(write.getTitle()),
            titleSpacing: 0,
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Opacity(
              opacity: write.sendable.value ? 1.0 : 0.5,
              child: FloatingActionButton.small(
                onPressed: !write.sendable.value ? null : write.send,
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
                      if (write.postData.value == null) const WriteSubject(),
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
    final dv = useMemoized(() => DataValue('settings', 'identities'));
    final identities = dv.list();
    final empty = name.text.isEmpty && email.text.isEmpty;
    useListenable(name);
    useListenable(email);
    useValueChanged(empty, (_, void _) => write.updateSendable());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            DropdownButton(
              isExpanded: true,
              value: write.identity,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text(enterIdentityText),
                ),
                ...identities.map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text('${dv.get(e)} <${dv.get(e)['email']}>'),
                  ),
                ),
              ],
              onChanged: (String? newValue) {
                write.identity = newValue ?? '';
              },
            ),
            if (write.identity.isEmpty) ...[
              TextField(
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  labelText: nameText,
                  errorText: name.text.isNotEmpty
                      ? null
                      : nameText + emptyInputText,
                ),
                controller: name,
                onChanged: (value) => write.name = name.text,
              ),
              TextField(
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
    useListenable(body);
    useValueChanged(body.text.isEmpty, (_, void _) => write.updateSendable());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            TextField(
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
                errorText: body.text.isNotEmpty
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
    final enable = useState(true);
    final signature = useTextEditingController(text: write.signature);
    useListenable(signature);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            TextField(
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
                value: enable.value,
                onChanged: (v) => enable.value = v!,
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
    final enable = useState(true);
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
                ),
                if (!all.value && write.needChop())
                  RichText(
                    text: TextSpan(
                      text: '${write.charChopped()} characters is chopped. ',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Quote all',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => write.quoteAll(),
                        ),
                        const TextSpan(text: ' '),
                      ],
                    ),
                  ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Checkbox(
                value: enable.value,
                onChanged: (v) => enable.value = v!,
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
                        label: const Text('Original'),
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
                        label: const Text('HQ Resize'),
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
                        label: const Text('Remove'),
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
