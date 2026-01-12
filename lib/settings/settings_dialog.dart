import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/data_store.dart';
import '../widgets/custom_dialog.dart';
import 'settings_block_list.dart';
import 'settings_data.dart';
import 'settings_identities.dart';
import 'settings_number.dart';
import 'settings_switch.dart';

class SettingsDialog extends HookWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) {
        return SettingsDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    return CustomDialog(
      constraints: BoxConstraints(minWidth: 600, maxWidth: 800),
      title: settingsText,
      child: Scrollbar(
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
                children: settingsData.map((e) => SettingsGroup(e)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroup extends HookWidget {
  const SettingsGroup(this.settings, {super.key});

  final SettingsItem settings;

  @override
  Widget build(BuildContext context) {
    final data = settings['data'] as List<SettingsItem>;
    final group = settings['setting'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(settings['name']),
          Card(
            child: Column(
              children: data
                  .map((e) {
                    return switch (e['default'].runtimeType) {
                      const (bool) => SettingsSwitch(group, e),
                      const (int) => SettingsNumber(group, e),
                      _ => switch (e['setting']) {
                        'identities' => SettingsIdentities(group, e),
                        'blockList' => SettingsBlockList(group, e),
                        _ => null,
                      },
                    };
                  })
                  .nonNulls
                  .cast<Widget>()
                  .separator(Divider(height: 1, indent: 1, endIndent: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

abstract class SettingsTileBase extends HookWidget {
  const SettingsTileBase(this.group, this.settings, {super.key});

  final String group;
  final SettingsItem settings;

  String get settingKey => 'settings.$group.${settings['setting']}';

  bool useEnabledBy() {
    final listenable = useMemoized(() {
      if (!settings.containsKey('enabledBy')) {
        return null;
      } else {
        final enabledBy = settings['enabledBy']!;
        final enabledByKey = 'settings.$group.$enabledBy';
        return DataValue.changed.where((e) => e?.$1 == enabledByKey, (
          enabledByKey,
          getSetting(group, enabledBy),
        ));
      }
    });
    return useListenableSelector(
      listenable,
      () => (listenable?.value?.$2 ?? true) as bool,
    );
  }

  void useSettingListenable() {
    final listenable = useMemoized(
      () => DataValue.changed.where((e) => e?.$1 == settingKey, null),
    );
    useListenable(listenable);
  }
}
