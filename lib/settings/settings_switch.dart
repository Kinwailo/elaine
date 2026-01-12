import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsSwitch extends SettingsTileBase {
  const SettingsSwitch(super.group, super.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final value = useState<bool>(getSetting(group, settings['setting']));
    void onTap() {
      setSetting(group, settings['setting'], !value.value);
      value.value = !value.value;
    }

    final enabled = useEnabledBy();
    useSettingListenable();
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
