import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../home/group_store.dart';
import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsGroupIdentity extends SettingsTileBase {
  const SettingsGroupIdentity(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = Modular.get<GroupStore>();
    final map = getSetting<Map>(group, settings['setting']);
    final enabled = useEnabledBy();
    useSettingListenable();
    return ListTile(
      dense: true,
      enabled: enabled,
      contentPadding: EdgeInsets.only(left: 12),
      onTap: () {},
      title: Text(settings['name']),
      subtitle: map.isEmpty
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
                  children: map.entries
                      .where((e) => groups.get(e.key) != null)
                      .map(
                        (e) => Transform.scale(
                          scale: 0.8,
                          child: InputChip(
                            isEnabled: enabled,
                            backgroundColor: colorScheme.secondaryContainer,
                            labelPadding: EdgeInsets.only(left: 6, right: 4),
                            label: Text(
                              '${groups.get(e.key)!.data.name}: ${e.value}',
                            ),
                            onDeleted: () {
                              setSetting(
                                group,
                                settings['setting'],
                                Map.fromEntries(
                                  map.entries.where((r) => r.key != e.key),
                                ),
                              );
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
