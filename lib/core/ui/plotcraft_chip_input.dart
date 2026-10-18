import 'package:flutter/material.dart';

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
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _hasFocus = _focus.hasFocus));
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Chips sit inside the field, before the text being typed, so the label
    // floats like in every other field of the form.
    return InputDecorator(
      isFocused: _hasFocus,
      isEmpty: false,
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final value in widget.values)
            InputChip(
              label: Text(value),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onDeleted: () => widget.onChanged(
                widget.values.where((item) => item != value).toList(),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
            child: IntrinsicWidth(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onSubmitted: _commit,
                onChanged: (value) {
                  if (value.endsWith(',')) _commit(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
