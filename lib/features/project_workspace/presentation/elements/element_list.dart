import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/ui/plotcraft_context_menu.dart';
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Feather.users, size: 28, color: theme.colorScheme.outline),
              const SizedBox(height: 10),
              Text(
                'elements.empty'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    // Grouped by type, in the order of the catalog, when the list is long
    // enough for headings to help.
    final groups = <(ElementType?, List<NarrativeElement>)>[
      for (final type in usedTypes)
        (
          type,
          [
            for (final element in visible)
              if (element.typeId == type.id) element,
          ],
        ),
    ].where((group) => group.$2.isNotEmpty).toList();
    final ungrouped = [
      for (final element in visible)
        if (!usedTypes.any((type) => type.id == element.typeId)) element,
    ];
    if (ungrouped.isNotEmpty) groups.add((null, ungrouped));
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (usedTypes.length > 1)
                      _FilterButton(
                        icon: Feather.layers,
                        label: 'elements.filter_type'.tr(),
                        allLabel: 'elements.all_types'.tr(),
                        value: typeId,
                        valueLabel: usedTypes
                            .where((type) => type.id == typeId)
                            .map((type) => type.label)
                            .firstOrNull,
                        options: {
                          for (final type in usedTypes) type.id: type.label,
                        },
                        onChanged: (value) => setState(() => _typeId = value),
                      ),
                    if (usedTypes.length > 1 && tags.isNotEmpty)
                      const SizedBox(width: 6),
                    if (tags.isNotEmpty)
                      _FilterButton(
                        icon: Feather.tag,
                        label: 'elements.filter_tag'.tr(),
                        allLabel: 'elements.all_tags'.tr(),
                        value: tag,
                        valueLabel: tag,
                        options: {for (final name in tags) name: name},
                        onChanged: (value) => setState(() => _tag = value),
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
              : ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final group in groups) ...[
                      if (groups.length > 1)
                        _GroupHeader(
                          label: group.$1?.label ?? '',
                          count: group.$2.length,
                        ),
                      for (final element in group.$2)
                        _row(element, group.$1, grouped: groups.length > 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _row(
    NarrativeElement element,
    ElementType? groupType, {
    required bool grouped,
  }) {
    final type =
        groupType ?? ElementTypeCatalog.resolve(element.typeId, widget.types);
    return PlotcraftContextRegion<ElementAction>(
      itemsBuilder: (_) => [
        PopupMenuItem(
          value: ElementAction.remove,
          child: Text('elements.remove'.tr()),
        ),
      ],
      onSelected: (action) => widget.onAction(element, action),
      child: PanelListItem(
        icon: (element.icon ?? type?.icon ?? IconRef.fallback).data,
        iconColor: element.color ?? type?.color,
        label: element.title,
        subtitle: grouped ? null : type?.label ?? element.typeId,
        selected: element.id == widget.activeElementId,
        onTap: () => widget.onOpen(element),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact filter: shows its name, or the chosen value when active, and opens
/// a menu with an "all" entry on top.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.allLabel,
    required this.value,
    required this.valueLabel,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String allLabel;
  final String? value;
  final String? valueLabel;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = value != null;
    return Flexible(
      child: PopupMenuButton<String>(
        tooltip: label,
        position: PopupMenuPosition.under,
        onSelected: (picked) => onChanged(picked.isEmpty ? null : picked),
        itemBuilder: (_) => [
          PopupMenuItem(value: '', child: Text(allLabel)),
          for (final option in options.entries)
            PopupMenuItem(value: option.key, child: Text(option.value)),
        ],
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  active ? (valueLabel ?? label) : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: active
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (active)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(null),
                  child: Icon(
                    Feather.x,
                    size: 13,
                    color: scheme.onPrimaryContainer,
                  ),
                )
              else
                Icon(
                  Feather.chevron_down,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
