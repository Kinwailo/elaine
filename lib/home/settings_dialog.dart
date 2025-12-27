import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../app/const.dart';

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
                  sliver: SuperSliverList.list(children: [
                    ],
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
