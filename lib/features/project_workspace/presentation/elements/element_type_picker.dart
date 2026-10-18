import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../domain/element_type.dart';
import 'element_type_label.dart';
import '../../../../core/icons/icon_data.dart';
import '../element_colors.dart';

/// Returned instead of a type ID when the person asks to create a new type.
const createElementTypeChoice = '\u0000create-type';

/// Prefix of the result when the person asks to edit a custom type; the type
/// ID follows it.
const editElementTypePrefix = '\u0000edit:';

/// Asks what kind of element to create: a grid of the available types, each
/// with its icon and color. Resolves to the chosen type ID,
/// [createElementTypeChoice], or null when dismissed.
Future<String?> showElementTypePicker(
  BuildContext context,
  List<ElementType> types, {
  bool allowCreate = false,
}) => showDialog<String>(
  context: context,
  builder: (dialogContext) => PlotcraftDialog(
    title: 'elements.choose_type'.tr(),
    maxWidth: 640,
    content: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text('elements.choose_type_hint'.tr()),
            ),
            ElementTypeGrid(
              types: types,
              allowCreate: allowCreate,
              onSelected: (id) => Navigator.pop(dialogContext, id),
            ),
          ],
        ),
      ),
    ),
    actions: [
      PlotcraftButton(
        label: 'preferences.cancel'.tr(),
        variant: PlotcraftButtonVariant.text,
        onPressed: () => Navigator.pop(dialogContext),
      ),
    ],
  ),
);

class ElementTypeGrid extends StatelessWidget {
  const ElementTypeGrid({
    super.key,
    required this.types,
    required this.onSelected,
    this.allowCreate = false,
  });

  final List<ElementType> types;
  final ValueChanged<String> onSelected;

  /// Adds a "new type" card that reports [createElementTypeChoice].
  final bool allowCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final builtin = [
      for (final type in types)
        if (type.builtin) type,
    ];
    final custom = [
      for (final type in types)
        if (!type.builtin) type,
    ];
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: .8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (builtin.isNotEmpty) ...[
          heading('elements.builtin_types'.tr()),
          _grid([
            for (final type in builtin)
              _TypeCard(
                icon: type.icon.data,
                color: type.color,
                label: type.label,
                hint: 'elements.type_hints.${type.id}'.tr(),
                onTap: () => onSelected(type.id),
              ),
          ]),
        ],
        if (custom.isNotEmpty || allowCreate) ...[
          const SizedBox(height: 22),
          heading('elements.custom_types'.tr()),
          _grid([
            for (final type in custom)
              _TypeCard(
                icon: type.icon.data,
                color: type.color,
                label: type.label,
                hint: 'elements.custom_type_hint'.tr(),
                onTap: () => onSelected(type.id),
                onEdit: () => onSelected('$editElementTypePrefix${type.id}'),
              ),
            if (allowCreate)
              _TypeCard(
                icon: Feather.plus,
                color: theme.colorScheme.primary,
                label: 'elements.new_type'.tr(),
                hint: 'elements.new_type_hint'.tr(),
                dashed: true,
                onTap: () => onSelected(createElementTypeChoice),
              ),
          ]),
        ],
      ],
    );
  }

  /// Two equal columns; a trailing odd card keeps the column width.
  Widget _grid(List<Widget> cards) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final width = constraints.maxWidth.isFinite
          ? (constraints.maxWidth - gap) / 2
          : 280.0;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    },
  );
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
    required this.onTap,
    this.dashed = false,
    this.onEdit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool dashed;

  /// Shows an edit button on the card (custom types only).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: dashed ? Colors.transparent : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        side: BorderSide(
          color: dashed ? scheme.outline : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                PlotcraftIconButton(
                  icon: Feather.edit_2,
                  tooltip: 'elements.edit_type'.tr(),
                  size: 14,
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
