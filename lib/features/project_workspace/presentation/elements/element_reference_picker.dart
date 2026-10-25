import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_reference.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import '../../../../core/icons/icon_data.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_chip.dart';
import '../element_colors.dart';
import 'element_picker_dialog.dart';
import 'element_type_label.dart';

/// Chooses the elements a detail points to ("where" of an event): a chip for
/// each, a menu to add more. Text left from before the detail could point to
/// elements shows as a plain chip until it is removed or replaced.
class ElementReferencePicker extends StatelessWidget {
  const ElementReferencePicker({
    super.key,
    required this.label,
    required this.value,
    required this.elements,
    required this.types,
    required this.targetTypes,
    required this.multiple,
    required this.onChanged,
    this.onOpen,
  });

  final String label;

  /// The detail as stored: IDs (or text) separated by commas.
  final String value;

  /// Every other element of the project.
  final List<NarrativeElement> elements;
  final List<ElementType> types;

  /// Types that can be chosen; empty means any.
  final List<String> targetTypes;
  final bool multiple;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onOpen;

  List<ReferenceToken> get _tokens =>
      ElementReferences.resolve(value, elements);

  String _raw(ReferenceToken token) =>
      token.isElement ? token.elementId! : token.text;

  void _emit(List<ReferenceToken> tokens) =>
      onChanged(ElementReferences.join(tokens.map(_raw)));

  Future<void> _pick(
    BuildContext context,
    List<ReferenceToken> tokens,
    List<NarrativeElement> selectable,
  ) async {
    final current = [
      for (final token in tokens)
        if (token.isElement) token.elementId!,
    ];
    final picked = await showElementPickerDialog(
      context,
      title: label,
      candidates: multiple
          ? selectable
          : [
              for (final element in selectable)
                if (!current.contains(element.id)) element,
            ],
      types: types,
      selected: multiple ? current : const [],
      multiple: multiple,
    );
    if (picked == null) return;
    // Text that matched no element stays until the person removes it.
    final leftovers = [
      for (final token in tokens)
        if (!token.isElement) token,
    ];
    final kept = [
      for (final id in current)
        if (picked.contains(id)) id,
    ];
    final added = [
      for (final id in picked)
        if (!kept.contains(id)) id,
    ];
    _emit([
      for (final id in [...kept, ...added]) ReferenceToken.element(id),
      ...leftovers,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = _tokens;
    final chosen = {
      for (final token in tokens)
        if (token.isElement) token.elementId!,
    };
    final candidates = [
      for (final element in elements)
        if (!chosen.contains(element.id) &&
            (targetTypes.isEmpty || targetTypes.contains(element.typeId)))
          element,
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final selectable = [
      for (final element in elements)
        if (targetTypes.isEmpty || targetTypes.contains(element.typeId))
          element,
    ];
    final canAdd = candidates.isNotEmpty && (multiple || tokens.isEmpty);
    final typeNames = [
      for (final id in targetTypes)
        ElementTypeCatalog.resolve(id, types)?.label ?? id,
    ];

    Widget chip(ReferenceToken token) {
      if (!token.isElement) {
        return Tooltip(
          message: 'elements.reference_unmatched'.tr(),
          child: PlotcraftChip(
            icon: Feather.alert_circle,
            iconColor: scheme.tertiary,
            label: token.text,
            onDeleted: () => _emit([
              for (final t in tokens)
                if (t != token) t,
            ]),
          ),
        );
      }
      final element = elements.firstWhere((e) => e.id == token.elementId);
      final type = ElementTypeCatalog.resolve(element.typeId, types);
      return PlotcraftChip(
        icon: (element.icon ?? type?.icon ?? IconRef.fallback).data,
        iconColor: element.color ?? type?.color ?? context.tokens.ink,
        label: element.title,
        onTap: onOpen == null ? null : () => onOpen!(element.id),
        onDeleted: () => _emit([
          for (final t in tokens)
            if (t != token) t,
        ]),
      );
    }

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final token in tokens) chip(token),
          if (canAdd || (multiple && selectable.isNotEmpty))
            PlotcraftChip(
              icon: Feather.plus,
              label: 'elements.reference_add'.tr(),
              onTap: () => _pick(context, tokens, selectable),
            )
          else if (candidates.isEmpty && tokens.isEmpty)
            Text(
              typeNames.isEmpty
                  ? 'elements.reference_none_any'.tr()
                  : 'elements.reference_none'.tr(
                      namedArgs: {'types': typeNames.join(', ')},
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
