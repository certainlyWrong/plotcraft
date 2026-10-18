import 'package:flutter/material.dart';

import 'plotcraft_text_field.dart';

/// Editable list of short values shown as chips (aliases, tags). Typing a
/// value and pressing Enter or a comma adds it; empty and repeated values
/// (ignoring case) are skipped.
class PlotcraftChipInput extends StatefulWidget {
  const PlotcraftChipInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final String? hint;

  @override
  State<PlotcraftChipInput> createState() => _PlotcraftChipInputState();
}

class _PlotcraftChipInputState extends State<PlotcraftChipInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final additions = raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final next = [...widget.values];
    for (final value in additions) {
      if (!next.any((item) => item.toLowerCase() == value.toLowerCase())) {
        next.add(value);
      }
    }
    _controller.clear();
    if (next.length != widget.values.length) widget.onChanged(next);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PlotcraftTextField(
        controller: _controller,
        focusNode: _focus,
        label: widget.label,
        hint: widget.hint,
        compact: true,
        onSubmitted: _commit,
        onChanged: (value) {
          if (value.endsWith(',')) _commit(value);
        },
      ),
      if (widget.values.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in widget.values)
              InputChip(
                label: Text(value),
                onDeleted: () => widget.onChanged(
                  widget.values.where((item) => item != value).toList(),
                ),
              ),
          ],
        ),
      ],
    ],
  );
}
