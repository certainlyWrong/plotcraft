import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/element_relation.dart';
import '../../domain/narrative_element.dart';

/// Links from an element to others ("sister of"), plus the links other
/// elements have to it, which are read-only here.
class ElementRelationsPanel extends StatefulWidget {
  const ElementRelationsPanel({
    super.key,
    required this.relations,
    required this.candidates,
    required this.incoming,
    required this.newId,
    required this.onChanged,
    required this.onOpenElement,
  });

  final List<ElementRelation> relations;

  /// Elements a relation may point to (every element except this one).
  final List<NarrativeElement> candidates;

  /// Relations stored on other elements that point to this one.
  final List<ResolvedRelation> incoming;
  final String Function() newId;
  final ValueChanged<List<ElementRelation>> onChanged;
  final ValueChanged<String> onOpenElement;

  @override
  State<ElementRelationsPanel> createState() => _ElementRelationsPanelState();
}

class _ElementRelationsPanelState extends State<ElementRelationsPanel> {
  final _labels = <String, TextEditingController>{};
  final _reciprocals = <String, TextEditingController>{};

  TextEditingController _labelOf(ElementRelation relation) =>
      _labels.putIfAbsent(
        relation.id,
        () => TextEditingController(text: relation.label),
      );

  TextEditingController _reciprocalOf(ElementRelation relation) =>
      _reciprocals.putIfAbsent(
        relation.id,
        () => TextEditingController(text: relation.reciprocalLabel),
      );

  @override
  void dispose() {
    for (final controller in [..._labels.values, ..._reciprocals.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _replace(ElementRelation next) => widget.onChanged([
    for (final relation in widget.relations)
      relation.id == next.id ? next : relation,
  ]);

  void _add() {
    if (widget.candidates.isEmpty) return;
    widget.onChanged([
      ...widget.relations,
      ElementRelation(id: widget.newId(), targetId: widget.candidates.first.id),
    ]);
  }

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
                'elements.relations'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PlotcraftButton(
              icon: Feather.plus,
              label: 'elements.add_relation'.tr(),
              variant: PlotcraftButtonVariant.text,
              onPressed: widget.candidates.isEmpty ? null : _add,
            ),
          ],
        ),
        if (widget.relations.isEmpty && widget.incoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.candidates.isEmpty
                  ? 'elements.no_other_elements'.tr()
                  : 'elements.no_relations'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (widget.relations.isNotEmpty) _columnHeaders(context),
        for (final relation in widget.relations) _row(context, relation),
        if (widget.incoming.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'elements.relations_incoming'.tr(),
            style: theme.textTheme.labelLarge,
          ),
          for (final view in widget.incoming)
            ListTile(
              dense: true,
              leading: const Icon(Feather.corner_down_left, size: 16),
              title: Text(view.other.title),
              subtitle: view.label.isEmpty ? null : Text(view.label),
              onTap: () => widget.onOpenElement(view.other.id),
            ),
        ],
      ],
    );
  }

  Widget _columnHeaders(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    Widget cell(String key) => Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(key.tr(), style: style),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          cell('elements.relation_col_target'),
          const SizedBox(width: 8),
          cell('elements.relation_col_label'),
          const SizedBox(width: 8),
          cell('elements.relation_col_reciprocal'),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ElementRelation relation) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: PlotcraftDropdown<String>(
            initialValue:
                widget.candidates.any((e) => e.id == relation.targetId)
                ? relation.targetId
                : null,
            items: [
              for (final element in widget.candidates)
                DropdownMenuItem(
                  value: element.id,
                  child: Text(element.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) _replace(relation.copyWith(targetId: id));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: PlotcraftTextField(
            controller: _labelOf(relation),
            compact: true,
            hint: 'elements.relation_label'.tr(),
            onChanged: (text) => _replace(relation.copyWith(label: text)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: PlotcraftTextField(
            controller: _reciprocalOf(relation),
            compact: true,
            hint: 'elements.relation_reciprocal'.tr(),
            onChanged: (text) =>
                _replace(relation.copyWith(reciprocalLabel: text)),
          ),
        ),
        PlotcraftIconButton(
          icon: Feather.x,
          tooltip: 'elements.remove'.tr(),
          onPressed: () => widget.onChanged([
            for (final item in widget.relations)
              if (item.id != relation.id) item,
          ]),
        ),
      ],
    ),
  );
}
