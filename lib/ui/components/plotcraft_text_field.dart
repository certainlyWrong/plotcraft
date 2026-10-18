import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlotcraftTextField extends StatelessWidget {
  const PlotcraftTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.compact = false,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLength,
    this.helperText,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final bool compact;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final String? helperText;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    minLines: minLines,
    maxLines: maxLines,
    textCapitalization: textCapitalization,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    maxLength: maxLength,
    maxLengthEnforcement: MaxLengthEnforcement.none,
    textInputAction: textInputAction,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      helperText: helperText,
      isDense: compact,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : null,
      alignLabelWithHint: (maxLines ?? 1) > 1,
    ),
  );
}
