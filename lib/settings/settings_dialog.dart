import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/data_store.dart';
import 'settings_block_list.dart';
import 'settings_data.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final scrollController = useScrollController();
    return Dialog(
      insetPadding: EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: 600, maxWidth: 800),
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
            automaticallyImplyLeading: false,
            title: Text(settingsText),
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
                    children: settingsData
                        .map((e) => SettingsGroup(e))
                        .toList(),
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
                  .map(
                    (e) => switch (e['default'].runtimeType) {
                      const (bool) => SettingsSwitch(group, e),
                      const (int) => SettingsNumber(group, e),
                      const (List<String>) when e['setting'] == 'blockList' =>
                        SettingsBlockList(group, e),
                      _ => null,
                    },
                  )
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

  String get enabledBy => settings['enabledBy'] ?? '';
  String get enabledByKey => 'settings.$group.$enabledBy';
  ValueListenable get enabledByListenable => DataValue.changed.where(
    (e) => e?.$1 == enabledByKey,
    (enabledByKey, getSetting(group, enabledBy)),
  );

  bool useEnabledBy() {
    final listenable = useMemoized(
      () => !settings.containsKey('enabledBy') ? null : enabledByListenable,
    );
    return useListenableSelector(
      listenable,
      () => (listenable?.value?.$2 ?? true) as bool,
    );
  }
}
