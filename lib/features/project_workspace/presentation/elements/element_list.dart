import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../domain/narrative_element.dart';
import '../shell/side_panel_widgets.dart';

enum ElementAction { remove }

/// Side panel listing the story elements.
class ElementList extends StatelessWidget {
  const ElementList({
    super.key,
    required this.elements,
    required this.activeElementId,
    required this.onOpen,
    required this.onAction,
  });

  final List<NarrativeElement> elements;
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
        return PlotcraftContextRegion<ElementAction>(
          itemsBuilder: (_) => [
            PopupMenuItem(
              value: ElementAction.remove,
              child: Text('elements.remove'.tr()),
            ),
          ],
          onSelected: (action) => onAction(element, action),
          child: PanelListItem(
            icon: element.kind == 'character' ? Feather.user : Feather.bookmark,
            label: element.title,
            subtitle: element.kind,
            selected: element.id == activeElementId,
            onTap: () => onOpen(element),
          ),
        );
      },
    );
  }
}
