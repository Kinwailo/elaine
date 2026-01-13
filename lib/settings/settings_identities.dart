import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/const.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_text_field.dart';
import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsIdentities extends SettingsTileBase {
  const SettingsIdentities(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = getSetting<List>(group, settings['setting']);
    final enabled = useEnabledBy();
    useSettingListenable();
    return ListTile(
      dense: true,
      enabled: enabled,
      contentPadding: EdgeInsets.only(left: 12),
      onTap: () {},
      title: Text(settings['name']),
      subtitle: list.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: -4,
                runSpacing: 0,
                children: list
                    .map((e) => IdentityChip(group, settings, e))
                    .toList(),
              ),
            ),
    );
  }
}

class IdentityChip extends HookWidget {
  const IdentityChip(this.group, this.settings, this.data, {super.key});

  final String group;
  final SettingsItem settings;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final list = getSetting<List>(group, settings['setting']);
    return Transform.scale(
      scale: 0.8,
      child: Theme(
        data: ThemeData.from(colorScheme: colorScheme, useMaterial3: false),
        child: InputChip(
          backgroundColor: colorScheme.secondaryContainer,
          selectedColor: colorScheme.tertiaryContainer,
          labelPadding: EdgeInsets.only(left: 6, right: 4),
          label: Text('${data["name"]} <${data["email"]}>'),
          tooltip: data["signature"],
          onPressed: () async {
            final edit = await IdentityDialog.show(context, data);
            if (edit == null) return;
            setSetting(
              group,
              settings['setting'],
              list.map((id) => id != data ? id : edit).toList(),
            );
          },
          onDeleted: () {
            setSetting(
              group,
              settings['setting'],
              list.where((id) => id != data).toList(),
            );
          },
        ),
      ),
    );
  }
}

class IdentityDialog extends HookWidget {
  const IdentityDialog(this.data, {super.key});

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) {
        return IdentityDialog(data);
      },
    );
  }

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = useTextEditingController(text: data['name']);
    final email = useTextEditingController(text: data['email']);
    final signature = useTextEditingController(text: data['signature']);
    final ids = getSetting<List>('group', 'identities');
    final nameExist = ids
        .whereNot((e) => e['name'] == data['name'])
        .any((e) => e['name'] == name.text);
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
              labelText: emailText,
              errorText: email.text.isNotEmpty
                  ? null
                  : emailText + emptyInputText,
              controller: email,
            ),
            CustomTextField(
              labelText: signatureText,
              maxLines: 5,
              controller: signature,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.maybePop(context, {
                    'name': name.text,
                    'email': email.text,
                    'signature': signature.text,
                  }),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
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
