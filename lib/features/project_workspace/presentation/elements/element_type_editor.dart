import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_color_picker.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_icon_picker.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/element_type.dart';

/// What the type editor decided.
sealed class ElementTypeEdit {
  const ElementTypeEdit();
}

class ElementTypeSaved extends ElementTypeEdit {
  const ElementTypeSaved(this.type);
  final ElementType type;
}

class ElementTypeDeleted extends ElementTypeEdit {
  const ElementTypeDeleted(this.typeId);
  final String typeId;
}

/// Creates or edits a custom element type: name, icon, color and fields.
/// [usedBy] is how many elements use the type; a type in use cannot be deleted.
Future<ElementTypeEdit?> showElementTypeEditor(
  BuildContext context, {
  ElementType? current,
  int usedBy = 0,
}) => showDialog<ElementTypeEdit>(
  context: context,
  builder: (_) => _ElementTypeEditor(current: current, usedBy: usedBy),
);

class _FieldRow {
  _FieldRow(ElementField field)
    : id = field.id,
      kind = field.kind,
      label = TextEditingController(text: field.label),
      options = TextEditingController(text: field.options.join(', '));

  final String id;
  ElementFieldKind kind;
  final TextEditingController label;
  final TextEditingController options;

  void dispose() {
    label.dispose();
    options.dispose();
  }
}

class _ElementTypeEditor extends StatefulWidget {
  const _ElementTypeEditor({required this.current, required this.usedBy});

  final ElementType? current;
  final int usedBy;

  @override
  State<_ElementTypeEditor> createState() => _ElementTypeEditorState();
}

class _ElementTypeEditorState extends State<_ElementTypeEditor> {
  late final _name = TextEditingController(text: widget.current?.name ?? '');
  late IconRef _icon = widget.current?.icon ?? const IconRef('Feather', 'star');
  late Color _color = widget.current?.color ?? plotcraftSwatches[8];
  late final List<_FieldRow> _rows = [
    for (final field in widget.current?.fields ?? const <ElementField>[])
      _FieldRow(field),
  ];
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  void _addField() => setState(
    () => _rows.add(_FieldRow(ElementField(id: _newId('f'), label: ''))),
  );

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    final fields = [
      for (final row in _rows)
        if (row.label.text.trim().isNotEmpty)
          ElementField(
            id: row.id,
            label: row.label.text.trim(),
            kind: row.kind,
            options: row.kind == ElementFieldKind.choice
                ? row.options.text
                      .split(',')
                      .map((option) => option.trim())
                      .where((option) => option.isNotEmpty)
                      .toList()
                : const [],
          ),
    ];
    Navigator.pop(
      context,
      ElementTypeSaved(
        ElementType(
          id: widget.current?.id ?? _newId('t'),
          name: _name.text.trim(),
          icon: _icon,
          color: _color,
          fields: fields,
        ),
      ),
    );
  }

  Future<void> _chooseIcon() async {
    final picked = await showIconPicker(context, current: _icon);
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.current != null;
    final inUse = widget.usedBy > 0;
    return PlotcraftDialog(
      title: editing ? 'elements.edit_type'.tr() : 'elements.create_type'.tr(),
      maxWidth: 600,
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'elements.type_icon'.tr(),
                    child: InkWell(
                      onTap: _chooseIcon,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: .16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon.data, size: 28, color: _color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PlotcraftTextField(
                      controller: _name,
                      autofocus: true,
                      label: 'elements.type_name'.tr(),
                      helperText: _showErrors && _name.text.trim().isEmpty
                          ? 'elements.title_required'.tr()
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'elements.type_color'.tr(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PlotcraftColorPicker(
                color: _color,
                onChanged: (color) => setState(() => _color = color),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'elements.type_fields'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  PlotcraftButton(
                    icon: Feather.plus,
                    label: 'elements.add_field'.tr(),
                    variant: PlotcraftButtonVariant.text,
                    onPressed: _addField,
                  ),
                ],
              ),
              if (_rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'ui.no_fields'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final row in _rows) _fieldRow(context, row),
            ],
          ),
        ),
      ),
      actions: [
        if (editing)
          Tooltip(
            message: inUse
                ? 'elements.type_in_use'.tr(
                    namedArgs: {'count': '${widget.usedBy}'},
                  )
                : '',
            child: PlotcraftButton(
              label: 'elements.delete_type'.tr(),
              variant: PlotcraftButtonVariant.destructive,
              onPressed: inUse
                  ? null
                  : () => Navigator.pop(
                      context,
                      ElementTypeDeleted(widget.current!.id),
                    ),
            ),
          ),
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(label: 'ui.save'.tr(), onPressed: _save),
      ],
    );
  }

  Widget _fieldRow(BuildContext context, _FieldRow row) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: PlotcraftTextField(
            controller: row.label,
            compact: true,
            hint: 'elements.field_label'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: PlotcraftDropdown<ElementFieldKind>(
            compact: true,
            initialValue: row.kind,
            items: [
              for (final kind in ElementFieldKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text('elements.field_kinds.${kind.name}'.tr()),
                ),
            ],
            onChanged: (kind) {
              if (kind != null) setState(() => row.kind = kind);
            },
          ),
        ),
        if (row.kind == ElementFieldKind.choice) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: PlotcraftTextField(
              controller: row.options,
              compact: true,
              hint: 'elements.field_options'.tr(),
            ),
          ),
        ],
        PlotcraftIconButton(
          icon: Feather.x,
          tooltip: 'elements.remove'.tr(),
          onPressed: () => setState(() {
            _rows.remove(row);
            row.dispose();
          }),
        ),
      ],
    ),
  );
}
