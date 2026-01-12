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
  });

  const CustomTextField.multi({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
    this.onChanged,
    this.contentPadding,
  }) : maxLines = null;

  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: mainTextStyle,
      minLines: 1,
      maxLines: maxLines,
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
