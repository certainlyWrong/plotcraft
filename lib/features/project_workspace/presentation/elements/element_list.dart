import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../../../core/icons/icon_ref.dart';
import '../../domain/element_type.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/narrative_element.dart';
import 'element_type_label.dart';
import '../shell/side_panel_widgets.dart';

enum ElementAction { remove }

/// Side panel listing the story elements.
class ElementList extends StatelessWidget {
  const ElementList({
    super.key,
    required this.elements,
    required this.types,
    required this.activeElementId,
    required this.onOpen,
    required this.onAction,
  });

  final List<NarrativeElement> elements;
  final List<ElementType> types;
  final String? activeElementId;
  final ValueChanged<NarrativeElement> onOpen;
  final void Function(NarrativeElement element, ElementAction action) onAction;

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'elements.empty'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final element = elements[index];
        final type = ElementTypeCatalog.resolve(element.typeId, types);
        return PlotcraftContextRegion<ElementAction>(
          itemsBuilder: (_) => [
            PopupMenuItem(
              value: ElementAction.remove,
              child: Text('elements.remove'.tr()),
            ),
          ],
          onSelected: (action) => onAction(element, action),
          child: PanelListItem(
            icon: (element.icon ?? type?.icon ?? IconRef.fallback).data,
            iconColor: element.color ?? type?.color,
            label: element.title,
            subtitle: type?.label ?? element.typeId,
            selected: element.id == activeElementId,
            onTap: () => onOpen(element),
          ),
        );
      },
    );
  }
}
