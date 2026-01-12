import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/data_store.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_text_field.dart';
import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsIdentities extends SettingsTileBase {
  const SettingsIdentities(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final list = getSetting<List>(group, settings['setting']);
    final listenable = useMemoized(
      () => DataValue.changed.where((e) => e?.$1 == settingKey, null),
    );
    useListenable(listenable);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 12),
      onTap: () {},
      title: Text(settings['name']),
      subtitle: list.isEmpty
          ? null
          : Theme(
              data: ThemeData.from(
                colorScheme: colorScheme,
                useMaterial3: false,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: -4,
                  runSpacing: 0,
                  children: list
                      .map(
                        (e) => Transform.scale(
                          scale: 0.8,
                          child: InputChip(
                            backgroundColor: colorScheme.secondaryContainer,
                            selectedColor: colorScheme.tertiaryContainer,
                            labelPadding: EdgeInsets.only(left: 6, right: 4),
                            label: Text('${e["name"]} <${e["email"]}>'),
                            tooltip: e["signature"],
                            onPressed: () => IdentityDialog.show(context),
                            onDeleted: () {
                              final list = getSetting<List>(
                                group,
                                settings['setting'],
                              );
                              setSetting(group, settings['setting'], [
                                ...list.where((b) => b != e),
                              ]);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}

class IdentityDialog extends HookWidget {
  const IdentityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) {
        return IdentityDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = useTextEditingController(text: '');
    final email = useTextEditingController(text: '');
    final signature = useTextEditingController(text: '');
    final ids = getSetting<List>('group', 'identities');
    final nameExist = ids.any((e) => e['name'] == name.text);
    useListenable(name);
    useListenable(email);
    return CustomDialog.simple(
      constraints: BoxConstraints(maxWidth: 300),
      title: editIdentityText,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            CustomTextField(
              labelText: nameText,
              errorText: nameExist
                  ? identityExist
                  : name.text.isNotEmpty
                  ? null
                  : nameText + emptyInputText,
              controller: name,
            ),
            CustomTextField(
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              labelText: emailText,
              errorText: email.text.isNotEmpty
                  ? null
                  : emailText + emptyInputText,
              controller: email,
            ),
            CustomTextField(
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              labelText: signatureText,
              maxLines: 5,
              controller: signature,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
