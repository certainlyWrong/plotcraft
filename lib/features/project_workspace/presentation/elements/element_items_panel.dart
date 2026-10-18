import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';

class ElementItem {
  const ElementItem({required this.title, required this.body, this.badge});

  final String title;
  final String body;

  /// Small text next to the title (for example where a phase starts).
  final String? badge;
}

/// A titled list of editable items (sections or phases of an element).
class ElementItemsPanel extends StatelessWidget {
  const ElementItemsPanel({
    super.key,
    required this.title,
    required this.emptyText,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String emptyText;
  final List<ElementItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PlotcraftButton(
              icon: Feather.plus,
              label: 'elements.add'.tr(),
              variant: PlotcraftButtonVariant.text,
              onPressed: onAdd,
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (var index = 0; index < items.length; index++)
          Card(
            child: ListTile(
              title: Row(
                children: [
                  Flexible(child: Text(items[index].title)),
                  if (items[index].badge != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      items[index].badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: items[index].body.trim().isEmpty
                  ? null
                  : Text(
                      items[index].body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => onEdit(index),
              trailing: PlotcraftIconButton(
                icon: Feather.x,
                tooltip: 'elements.remove'.tr(),
                onPressed: () => onRemove(index),
                size: 17,
              ),
            ),
          ),
      ],
    );
  }
}
