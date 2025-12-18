import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_launcher/link.dart';

class AppLink extends StatelessWidget {
  const AppLink({
    super.key,
    required this.root,
    required this.paths,
    this.onTap,
    this.child,
  });

  final String root;
  final List<String> paths;
  final void Function()? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final link = [root, ...paths].join('/');
    return Link(
      uri: Uri.parse('/$link'),
      builder: (_, _) => InkWell(
        onTap: () async {
          Modular.to.pushNamedAndRemoveUntil(
            '/$link',
            ModalRoute.withName('/$root/'),
          );
          onTap?.call();
        },
        child: child,
      ),
    );
  }
}
