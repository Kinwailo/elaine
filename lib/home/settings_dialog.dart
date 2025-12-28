import 'package:elaine/home/settings_data.dart';
import 'package:elaine/services/data_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';
import '../app/utils.dart';

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
                      const (bool) => SettingsSwitchTile(group, e),
                      const (int) => SettingsNumberTile(group, e),
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

class SettingsSwitchTile extends SettingsTileBase {
  const SettingsSwitchTile(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final value = useState<bool>(getSetting(group, settings['setting']));
    void onTap() {
      setSetting(group, settings['setting'], !value.value);
      value.value = !value.value;
    }

    final enabled = useEnabledBy();
    return ListTile(
      dense: true,
      enabled: enabled,
      contentPadding: EdgeInsets.only(left: 12),
      onTap: onTap,
      title: Text(settings['name']),
      trailing: Transform.scale(
        scale: 0.6,
        child: Switch(
          value: value.value,
          onChanged: !enabled ? null : (_) => onTap(),
        ),
      ),
    );
  }
}

class SettingsNumberTile extends SettingsTileBase {
  const SettingsNumberTile(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final value = useValueNotifier<int>(getSetting(group, settings['setting']));
    final text = useTextEditingController(text: '${value.value}');
    final delta = useValueNotifier(0.0);
    final step = settings['step'] as int;
    final min = settings['min'] as int;
    final max = settings['max'] as int;
    void setValue(int v) {
      v = v.clamp(min, max);
      value.value = v;
      text.text = '$v';
      setSetting(group, settings['setting'], v);
    }

    final enabled = useEnabledBy();
    return GestureDetector(
      onHorizontalDragStart: (_) => delta.value = 0.0,
      onHorizontalDragUpdate: (details) {
        delta.value += details.primaryDelta ?? 0.0;
        setValue(value.value + step * (delta.value ~/ 20.0));
        delta.value = delta.value.remainder(20.0);
      },
      child: ListTile(
        dense: true,
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.resizeLeftRight
            : SystemMouseCursors.basic,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        onTap: () {},
        title: Text(settings['name']),
        trailing: TextField(
          enabled: enabled,
          controller: text,
          style: subTextStyle,
          textAlign: TextAlign.center,
          decoration: InputDecoration.collapsed(
            hintText: null,
            border: UnderlineInputBorder(),
            constraints: BoxConstraints(maxWidth: 40),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onSubmitted: (value) =>
              setValue(int.tryParse(text.text) ?? settings['default']),
        ),
      ),
    );
  }
}
