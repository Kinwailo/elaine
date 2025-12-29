import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/utils.dart';
import '../services/data_store.dart';
import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsBlockList extends SettingsTileBase {
  const SettingsBlockList(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final list = getSetting<List>(group, settings['setting']);
    final enabled = useEnabledBy();
    final key = 'settings.ui.blockList';
    final listenable = useMemoized(
      () => DataValue.changed.where((e) => e?.$1 == key, null),
    );
    useListenable(listenable);
    return ListTile(
      dense: true,
      enabled: enabled,
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
                  spacing: 8,
                  runSpacing: 4,
                  children: list
                      .map(
                        (e) => InputChip(
                          isEnabled: enabled,
                          backgroundColor: colorScheme.secondaryContainer,
                          labelPadding: EdgeInsets.only(left: 6, right: 4),
                          label: Text(e),
                          onDeleted: () {
                            final list = getSetting<List>('ui', 'blockList');
                            setSetting('ui', 'blockList', [
                              ...list.where((b) => b != e),
                            ]);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}
