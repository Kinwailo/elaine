import 'package:flutter/material.dart';

import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsBlockList extends SettingsTileBase {
  const SettingsBlockList(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                            isEnabled: enabled,
                            backgroundColor: colorScheme.secondaryContainer,
                            labelPadding: EdgeInsets.only(left: 6, right: 4),
                            label: Text(e),
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
