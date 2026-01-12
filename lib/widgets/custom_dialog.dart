import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class CustomDialog extends HookWidget {
  const CustomDialog({
    super.key,
    this.messengerKey,
    this.constraints,
    this.title,
    this.floatingActionButton,
    required this.child,
  }) : simple = false;

  const CustomDialog.simple({
    super.key,
    this.constraints,
    this.title,
    required this.child,
  }) : simple = true,
       messengerKey = null,
       floatingActionButton = null;

  final Key? messengerKey;
  final BoxConstraints? constraints;
  final String? title;
  final Widget? floatingActionButton;
  final Widget child;

  final bool simple;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.outline.withValues(alpha: 0.5);
    return Dialog(
      insetPadding: EdgeInsets.all(8),
      constraints: constraints,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadiusGeometry.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(8),
        child: ScaffoldMessenger(
          key: messengerKey,
          child: PointerInterceptor(
            child: simple
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        toolbarHeight: kToolbarHeight - 12,
                        automaticallyImplyLeading: false,
                        title: Text(title ?? ''),
                        titleSpacing: 10,
                      ),
                      Divider(height: 1, color: color),
                      child,
                    ],
                  )
                : Scaffold(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    appBar: AppBar(
                      toolbarHeight: kToolbarHeight - 12,
                      automaticallyImplyLeading: false,
                      title: Text(title ?? ''),
                      titleSpacing: 10,
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
                    floatingActionButton: floatingActionButton,
                    body: child,
                  ),
          ),
        ),
      ),
    );
  }
}
