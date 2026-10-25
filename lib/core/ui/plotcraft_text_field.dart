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
    this.expands = false,
    this.textAlignVertical,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.focusNode,
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
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    minLines: expands ? null : minLines,
    maxLines: expands ? null : maxLines,
    expands: expands,
    textAlignVertical: textAlignVertical,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    readOnly: readOnly,
    onTap: onTap,
    focusNode: focusNode,
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
      suffixIcon: suffixIcon,
      helperText: helperText,
      isDense: compact,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 2, vertical: 8)
          : null,
      alignLabelWithHint: expands || (maxLines ?? 1) > 1,
    ),
  );
}
