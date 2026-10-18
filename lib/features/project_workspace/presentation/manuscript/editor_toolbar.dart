import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_popup_menu.dart';
import '../../../../core/ui/plotcraft_segmented.dart';
import '../../domain/narrative_element.dart';

enum EditorView { write, split, preview }

/// Formatting and view controls of the Markdown editor.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.undo,
    required this.elements,
    required this.view,
    required this.fullscreen,
    required this.canSave,
    required this.onWrap,
    required this.onPrefix,
    required this.onInsertElement,
    required this.onFind,
    required this.onViewChanged,
    required this.onToggleFullscreen,
    required this.onSave,
  });

  final UndoHistoryController undo;
  final List<NarrativeElement> elements;
  final EditorView view;
  final bool fullscreen;
  final bool canSave;
  final void Function(String before, [String after]) onWrap;
  final ValueChanged<String> onPrefix;
  final ValueChanged<NarrativeElement> onInsertElement;
  final VoidCallback onFind;
  final ValueChanged<EditorView> onViewChanged;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            ValueListenableBuilder<UndoHistoryValue>(
              valueListenable: undo,
              builder: (_, value, _) => Row(
                children: [
                  PlotcraftIconButton(
                    icon: Feather.corner_up_left,
                    tooltip: 'book.undo'.tr(),
                    onPressed: value.canUndo ? undo.undo : null,
                  ),
                  PlotcraftIconButton(
                    icon: Feather.corner_up_right,
                    tooltip: 'book.redo'.tr(),
                    onPressed: value.canRedo ? undo.redo : null,
                  ),
                ],
              ),
            ),
            _tool(Feather.bold, 'book.bold', () => onWrap('**', '**')),
            _tool(Feather.italic, 'book.italic', () => onWrap('*', '*')),
            _tool(Feather.type, 'book.heading', () => onPrefix('## ')),
            _tool(Feather.list, 'book.list', () => onPrefix('- ')),
            _tool(Feather.check_square, 'book.task', () => onPrefix('- [ ] ')),
            _tool(Feather.message_square, 'book.quote', () => onPrefix('> ')),
            _tool(Feather.code, 'book.code', () => onWrap('`', '`')),
            _tool(Feather.link, 'book.link', () => onWrap('[', '](https://)')),
            if (elements.isNotEmpty)
              PlotcraftPopupMenuButton<NarrativeElement>(
                tooltip: 'book.insert_element'.tr(),
                icon: const Icon(Feather.at_sign, size: 18),
                onSelected: onInsertElement,
                itemBuilder: (_) => [
                  for (final element in elements)
                    PopupMenuItem(value: element, child: Text(element.title)),
                ],
              ),
            _tool(Feather.search, 'book.find', onFind),
            const SizedBox(width: 8),
            PlotcraftSegmented<EditorView>(
              segments: [
                PlotcraftSegment(
                  value: EditorView.write,
                  icon: Feather.edit_3,
                  tooltip: 'book.write'.tr(),
                ),
                PlotcraftSegment(
                  value: EditorView.split,
                  icon: Feather.layout,
                  tooltip: 'book.split'.tr(),
                ),
                PlotcraftSegment(
                  value: EditorView.preview,
                  icon: Feather.eye,
                  tooltip: 'book.preview'.tr(),
                ),
              ],
              selected: view,
              onChanged: onViewChanged,
            ),
            const SizedBox(width: 8),
            PlotcraftIconButton(
              icon: fullscreen ? Feather.minimize_2 : Feather.maximize_2,
              tooltip: fullscreen
                  ? 'book.exit_fullscreen'.tr()
                  : 'book.fullscreen'.tr(),
              onPressed: onToggleFullscreen,
            ),
            PlotcraftIconButton(
              icon: Feather.save,
              tooltip: 'workspace.save'.tr(),
              onPressed: canSave ? onSave : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ),
  );

  Widget _tool(IconData icon, String key, VoidCallback onPressed) =>
      PlotcraftIconButton(icon: icon, tooltip: key.tr(), onPressed: onPressed);
}
