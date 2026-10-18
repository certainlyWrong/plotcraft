import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/element_filter.dart';
import '../../domain/element_type.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/narrative_element.dart';
import '../shell/side_panel_widgets.dart';
import 'element_type_label.dart';

enum ElementAction { remove }

/// Side panel listing the story elements, with search and filters by type
/// and tag.
class ElementList extends StatefulWidget {
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
  State<ElementList> createState() => _ElementListState();
}

class _ElementListState extends State<ElementList> {
  final _search = TextEditingController();
  String? _typeId;
  String? _tag;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.elements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'elements.empty'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final usedTypes = [
      for (final type in widget.types)
        if (widget.elements.any((element) => element.typeId == type.id)) type,
    ];
    final tags = tagsOf(widget.elements);
    // A filter whose value no longer exists (the last element of that type was
    // changed) is treated as "all".
    final typeId = usedTypes.any((type) => type.id == _typeId) ? _typeId : null;
    final tag = tags.contains(_tag) ? _tag : null;
    final visible = filterElements(
      widget.elements,
      query: _search.text,
      typeId: typeId,
      tag: tag,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: PlotcraftTextField(
                  controller: _search,
                  compact: true,
                  hint: 'elements.search'.tr(),
                  prefixIcon: const Icon(Feather.search, size: 15),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (usedTypes.length > 1 || tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (usedTypes.length > 1)
                      Expanded(
                        child: PlotcraftDropdown<String>(
                          initialValue: typeId ?? '',
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text('elements.all_types'.tr()),
                            ),
                            for (final type in usedTypes)
                              DropdownMenuItem(
                                value: type.id,
                                child: Text(
                                  type.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _typeId = value == null || value.isEmpty
                                ? null
                                : value,
                          ),
                        ),
                      ),
                    if (usedTypes.length > 1 && tags.isNotEmpty)
                      const SizedBox(width: 6),
                    if (tags.isNotEmpty)
                      Expanded(
                        child: PlotcraftDropdown<String>(
                          initialValue: tag ?? '',
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text('elements.all_tags'.tr()),
                            ),
                            for (final name in tags)
                              DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _tag = value == null || value.isEmpty
                                ? null
                                : value,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'elements.no_matches'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final element = visible[index];
                    final type = ElementTypeCatalog.resolve(
                      element.typeId,
                      widget.types,
                    );
                    return PlotcraftContextRegion<ElementAction>(
                      itemsBuilder: (_) => [
                        PopupMenuItem(
                          value: ElementAction.remove,
                          child: Text('elements.remove'.tr()),
                        ),
                      ],
                      onSelected: (action) => widget.onAction(element, action),
                      child: PanelListItem(
                        icon: (element.icon ?? type?.icon ?? IconRef.fallback)
                            .data,
                        iconColor: element.color ?? type?.color,
                        label: element.title,
                        subtitle: type?.label ?? element.typeId,
                        selected: element.id == widget.activeElementId,
                        onTap: () => widget.onOpen(element),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
