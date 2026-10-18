import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../domain/element_type.dart';
import 'element_type_label.dart';

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
      child: ElementTypeGrid(
        types: types,
        allowCreate: allowCreate,
        onSelected: (id) => Navigator.pop(dialogContext, id),
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
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final type in types)
        _TypeCard(
          icon: type.icon.data,
          color: type.color,
          label: type.label,
          onTap: () => onSelected(type.id),
          onEdit: type.builtin
              ? null
              : () => onSelected('$editElementTypePrefix${type.id}'),
        ),
      if (allowCreate)
        _TypeCard(
          icon: Feather.plus,
          color: Theme.of(context).colorScheme.outline,
          label: 'elements.new_type'.tr(),
          dashed: true,
          onTap: () => onSelected(createElementTypeChoice),
        ),
    ],
  );
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.dashed = false,
    this.onEdit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool dashed;

  /// Shows an edit button on the card (custom types only).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 140,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
          side: BorderSide(
            color: dashed ? scheme.outline : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 26, color: color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: PlotcraftIconButton(
                    icon: Feather.edit_2,
                    tooltip: 'elements.edit_type'.tr(),
                    size: 14,
                    onPressed: onEdit,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
