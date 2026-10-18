import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/element_type.dart';
import '../../domain/narrative_element.dart';
import 'element_type_label.dart';

/// Inputs for the details defined by an element's type. Values are strings
/// keyed by field ID; a value left empty is not saved. Give the panel a key
/// that changes with the type so its inputs are rebuilt.
class ElementFieldsPanel extends StatefulWidget {
  const ElementFieldsPanel({
    super.key,
    required this.type,
    required this.values,
    required this.otherElements,
    required this.onChanged,
  });

  final ElementType type;
  final Map<String, String> values;

  /// Elements a field of kind "element" can point to.
  final List<NarrativeElement> otherElements;
  final void Function(String fieldId, String value) onChanged;

  @override
  State<ElementFieldsPanel> createState() => _ElementFieldsPanelState();
}

class _ElementFieldsPanelState extends State<ElementFieldsPanel> {
  final _controllers = <String, TextEditingController>{};

  TextEditingController _controller(ElementField field) =>
      _controllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: widget.values[field.id] ?? ''),
      );

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(ElementField field) async {
    final controller = _controller(field);
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1),
      lastDate: DateTime(9999),
      helpText: 'elements.pick_date'.tr(),
    );
    if (picked == null) return;
    final iso = picked.toIso8601String().substring(0, 10);
    controller.text = iso;
    widget.onChanged(field.id, iso);
  }

  Widget _input(ElementField field) {
    final value = widget.values[field.id] ?? '';
    final label = field.displayLabel;
    switch (field.kind) {
      case ElementFieldKind.text:
        return PlotcraftTextField(
          controller: _controller(field),
          label: label,
          onChanged: (text) => widget.onChanged(field.id, text),
        );
      case ElementFieldKind.longText:
        return PlotcraftTextField(
          controller: _controller(field),
          label: label,
          minLines: 2,
          maxLines: 6,
          onChanged: (text) => widget.onChanged(field.id, text),
        );
      case ElementFieldKind.url:
        return PlotcraftTextField(
          controller: _controller(field),
          label: label,
          keyboardType: TextInputType.url,
          prefixIcon: const Icon(Feather.link, size: 16),
          onChanged: (text) => widget.onChanged(field.id, text),
        );
      case ElementFieldKind.number:
        return PlotcraftTextField(
          controller: _controller(field),
          label: label,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[.,]?\d*')),
          ],
          onChanged: (text) => widget.onChanged(field.id, text),
        );
      case ElementFieldKind.date:
        return PlotcraftTextField(
          controller: _controller(field),
          label: label,
          readOnly: true,
          onTap: () => _pickDate(field),
          suffixIcon: const Icon(Feather.calendar, size: 16),
        );
      case ElementFieldKind.choice:
        return PlotcraftDropdown<String>(
          initialValue: field.options.contains(value) ? value : '',
          items: [
            DropdownMenuItem(
              value: '',
              child: Text('${field.displayLabel}: ${'elements.none'.tr()}'),
            ),
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (option) {
            setState(() {});
            widget.onChanged(field.id, option ?? '');
          },
        );
      case ElementFieldKind.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          value: value == 'true',
          onChanged: (on) {
            setState(() {});
            widget.onChanged(field.id, on ? 'true' : 'false');
          },
        );
      case ElementFieldKind.element:
        return PlotcraftDropdown<String>(
          initialValue: widget.otherElements.any((e) => e.id == value)
              ? value
              : '',
          items: [
            DropdownMenuItem(
              value: '',
              child: Text('$label: ${'elements.none'.tr()}'),
            ),
            for (final element in widget.otherElements)
              DropdownMenuItem(value: element.id, child: Text(element.title)),
          ],
          onChanged: (id) {
            setState(() {});
            widget.onChanged(field.id, id ?? '');
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.type.fields;
    if (fields.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.details'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final half = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final field in fields)
                  SizedBox(
                    width:
                        field.kind == ElementFieldKind.longText ||
                            field.kind == ElementFieldKind.url ||
                            constraints.maxWidth < 520
                        ? constraints.maxWidth
                        : half,
                    child: _input(field),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
