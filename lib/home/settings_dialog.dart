import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    return Dialog(
      insetPadding: EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: 800, maxWidth: 1200),
      child: Column(children: [Checkbox(value: true, onChanged: (_) {})]),
    );
  }
}
