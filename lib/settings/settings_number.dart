import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/const.dart';
import 'settings_data.dart';
import 'settings_dialog.dart';

class SettingsNumber extends SettingsTileBase {
  const SettingsNumber(super.group, super.settings, {super.key});

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
    useSettingListenable();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
