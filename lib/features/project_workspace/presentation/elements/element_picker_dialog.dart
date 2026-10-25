import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_index.dart';

import '../../../../core/icons/icon_data.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../element_colors.dart';
import 'element_type_label.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

/// Searches [candidates] and returns the IDs the person picked, in the order
/// they were picked (those already in [selected] first), or null if cancelled.
/// With [multiple] each tap toggles an element and "Apply" confirms; without
/// it a tap (or Enter on the first result) picks one and closes.
Future<List<String>?> showElementPickerDialog(
  BuildContext context, {
  required String title,
  required List<NarrativeElement> candidates,
  required List<ElementType> types,
  required List<String> selected,
  required bool multiple,
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _ElementPickerDialog(
    title: title,
    candidates: candidates,
    types: types,
    selected: selected,
    multiple: multiple,
  ),
);

class _ElementPickerDialog extends StatefulWidget {
  const _ElementPickerDialog({
    required this.title,
    required this.candidates,
    required this.types,
    required this.selected,
    required this.multiple,
  });

  final String title;
  final List<NarrativeElement> candidates;
  final List<ElementType> types;
  final List<String> selected;
  final bool multiple;

  @override
  State<_ElementPickerDialog> createState() => _ElementPickerDialogState();
}

class _ElementPickerDialogState extends State<_ElementPickerDialog> {
  final _query = TextEditingController();
  late final List<String> _picked = [...widget.selected];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _typeLabel(NarrativeElement element) =>
      ElementTypeCatalog.resolve(element.typeId, widget.types)?.label ??
      element.typeId;

  /// Elements that match the text in the title, an alias, the type or the
  /// summary (accents and case ignored); titles that start with it come first.
  List<NarrativeElement> get _matches {
    final query = MentionIndex.fold(_query.text.trim());
    final sorted = [...widget.candidates]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (query.isEmpty) return sorted;
    int rank(NarrativeElement e) {
      final title = MentionIndex.fold(e.title);
      if (title.startsWith(query)) return 0;
      if (title.contains(query)) return 1;
      if (e.aliases.any((a) => MentionIndex.fold(a).contains(query))) return 2;
      if (MentionIndex.fold(_typeLabel(e)).contains(query)) return 3;
      if (MentionIndex.fold(e.summary).contains(query)) return 4;
      return -1;
    }

    final ranked = [
      for (final element in sorted)
        if (rank(element) >= 0) (rank(element), element),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final item in ranked) item.$2];
  }

  void _choose(NarrativeElement element) {
    if (!widget.multiple) {
      Navigator.pop(context, [element.id]);
      return;
    }
    setState(() {
      if (!_picked.remove(element.id)) _picked.add(element.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final matches = _matches;
    return PlotcraftDialog(
      title: widget.title,
      maxWidth: 460,
      content: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlotcraftTextField(
              controller: _query,
              autofocus: true,
              hint: 'elements.reference_search'.tr(),
              prefixIcon: const Icon(Feather.search, size: 16),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (matches.isNotEmpty) _choose(matches.first);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'elements.reference_no_results'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final element = matches[index];
                        final type = ElementTypeCatalog.resolve(
                          element.typeId,
                          widget.types,
                        );
                        final on = _picked.contains(element.id);
                        return ListTile(
                          dense: true,
                          selected: on,
                          leading: Icon(
                            (element.icon ?? type?.icon ?? IconRef.fallback)
                                .data,
                            size: 18,
                            color:
                                element.color ??
                                type?.color ??
                                context.tokens.ink,
                          ),
                          title: Text(
                            element.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _typeLabel(element),
                            style: theme.textTheme.labelSmall,
                          ),
                          trailing: widget.multiple
                              ? Checkbox(
                                  value: on,
                                  onChanged: (_) => _choose(element),
                                )
                              : null,
                          onTap: () => _choose(element),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        if (widget.multiple)
          PlotcraftButton(
            label: 'ui.apply'.tr(),
            onPressed: () => Navigator.pop(context, _picked),
          ),
      ],
    );
  }
}
