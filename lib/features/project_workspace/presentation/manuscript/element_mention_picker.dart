import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/element_filter.dart';
import '../../domain/element_type.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/narrative_element.dart';
import '../elements/element_type_label.dart';
import '../../../../core/icons/icon_data.dart';
import '../element_colors.dart';

/// Search-and-choose list of story elements, opened by typing `@` or from the
/// toolbar. Arrow keys move, Enter chooses, Escape closes. Resolves to the
/// chosen element or null.
Future<NarrativeElement?> showElementMentionPicker(
  BuildContext context, {
  required List<NarrativeElement> elements,
  required List<ElementType> types,
}) => showDialog<NarrativeElement>(
  context: context,
  builder: (_) => _MentionPicker(elements: elements, types: types),
);

class _MentionPicker extends StatefulWidget {
  const _MentionPicker({required this.elements, required this.types});

  final List<NarrativeElement> elements;
  final List<ElementType> types;

  @override
  State<_MentionPicker> createState() => _MentionPickerState();
}

class _MentionPickerState extends State<_MentionPicker> {
  final _search = TextEditingController();
  int _highlight = 0;

  List<NarrativeElement> get _visible =>
      filterElements(widget.elements, query: _search.text);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final count = _visible.length;
    if (count == 0) return;
    setState(() => _highlight = (_highlight + delta) % count);
  }

  void _choose([NarrativeElement? element]) {
    final list = _visible;
    final chosen =
        element ??
        (list.isEmpty ? null : list[_highlight.clamp(0, list.length - 1)]);
    if (chosen != null) Navigator.pop(context, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = _visible;
    return Dialog(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
          const SingleActivator(LogicalKeyboardKey.enter): _choose,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _choose,
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'editor.mention_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                PlotcraftTextField(
                  controller: _search,
                  autofocus: true,
                  compact: true,
                  hint: 'elements.search'.tr(),
                  prefixIcon: const Icon(Feather.search, size: 15),
                  onChanged: (_) => setState(() => _highlight = 0),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: visible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              widget.elements.isEmpty
                                  ? 'editor.no_elements'.tr()
                                  : 'elements.no_matches'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final element = visible[index];
                            final type = ElementTypeCatalog.resolve(
                              element.typeId,
                              widget.types,
                            );
                            final selected = index == _highlight;
                            return Material(
                              color: selected
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                PlotcraftRadii.control,
                              ),
                              child: ListTile(
                                dense: true,
                                selected: selected,
                                leading: Icon(
                                  (element.icon ??
                                          type?.icon ??
                                          IconRef.fallback)
                                      .data,
                                  size: 18,
                                  color: element.color ?? type?.color,
                                ),
                                title: Text(element.title),
                                subtitle: Text(type?.label ?? element.typeId),
                                onTap: () => _choose(element),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
