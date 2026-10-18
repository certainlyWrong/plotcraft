import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/count_label.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../../../core/ui/plotcraft_popup_menu.dart';
import '../../domain/book_content.dart';
import '../shell/side_panel_widgets.dart';

enum ChapterAction { rename, up, down, remove }

/// Side panel for the manuscript: the chapters, in reading order. A chapter
/// can be dragged to a new place or moved with its menu.
class ChapterList extends StatelessWidget {
  const ChapterList({
    super.key,
    required this.book,
    required this.activeChapterId,
    required this.busy,
    required this.onOpen,
    required this.onAction,
    required this.onReorder,
    required this.onAdd,
  });

  final BookContent book;
  final String? activeChapterId;
  final bool busy;
  final ValueChanged<String> onOpen;
  final void Function(BookChapter chapter, ChapterAction action) onAction;

  /// Reports the chapter's new position, adjusted for the removal.
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAdd;

  List<PopupMenuEntry<ChapterAction>> _menu(int index) => [
    PopupMenuItem(value: ChapterAction.rename, child: Text('book.rename'.tr())),
    if (index > 0)
      PopupMenuItem(value: ChapterAction.up, child: Text('book.move_up'.tr())),
    if (index < book.chapters.length - 1)
      PopupMenuItem(
        value: ChapterAction.down,
        child: Text('book.move_down'.tr()),
      ),
    if (book.chapters.length > 1)
      PopupMenuItem(
        value: ChapterAction.remove,
        child: Text('book.remove_chapter'.tr()),
      ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          buildDefaultDragHandles: false,
          itemCount: book.chapters.length,
          onReorderItem: (oldIndex, newIndex) {
            if (!busy) onReorder(oldIndex, newIndex);
          },
          proxyDecorator: (child, _, _) =>
              Material(color: Colors.transparent, child: child),
          itemBuilder: (context, index) {
            final chapter = book.chapters[index];
            final words = _words(book.chapterTexts[chapter.id] ?? '');
            return ReorderableDragStartListener(
              key: ValueKey(chapter.id),
              index: index,
              child: PlotcraftContextRegion<ChapterAction>(
                itemsBuilder: (_) => _menu(index),
                onSelected: (action) => onAction(chapter, action),
                child: PanelListItem(
                  icon: Feather.file_text,
                  label: chapter.title,
                  subtitle: countLabel('workspace.word_count', words),
                  selected: chapter.id == activeChapterId,
                  onTap: () => onOpen(chapter.id),
                  trailing: PlotcraftPopupMenuButton<ChapterAction>(
                    tooltip: 'book.chapter_actions'.tr(),
                    icon: const Icon(Feather.more_horizontal, size: 15),
                    onSelected: (action) => onAction(chapter, action),
                    itemBuilder: (_) => _menu(index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: PlotcraftButton(
          icon: Feather.plus,
          label: 'book.add_chapter'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: busy ? null : onAdd,
        ),
      ),
    ],
  );

  static int _words(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
  }
}
