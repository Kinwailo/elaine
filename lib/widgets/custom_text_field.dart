import 'package:flutter/material.dart';

import '../app/const.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
    this.onChanged,
    this.contentPadding,
    this.maxLines = 1,
    this.enabled = true,
  });

  const CustomTextField.multi({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
    this.onChanged,
    this.contentPadding,
    this.enabled = true,
  }) : maxLines = null;

  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final int? maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: mainTextStyle,
      minLines: 1,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: const UnderlineInputBorder(),
        contentPadding: contentPadding ?? const EdgeInsets.all(4),
        labelText: labelText,
        errorText: errorText,
      ),
      controller: controller,
      onChanged: onChanged,
    );
  }
}
