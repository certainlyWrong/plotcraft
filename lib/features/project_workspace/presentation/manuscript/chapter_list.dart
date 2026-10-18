import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../../../core/ui/plotcraft_popup_menu.dart';
import '../../domain/book_content.dart';
import '../shell/side_panel_widgets.dart';

enum ChapterAction { rename, up, down, remove }

/// Side panel for the manuscript: the single manuscript or the chapter list.
class ChapterList extends StatelessWidget {
  const ChapterList({
    super.key,
    required this.book,
    required this.activeChapterId,
    required this.singleActive,
    required this.busy,
    required this.onOpen,
    required this.onOpenSingle,
    required this.onAction,
    required this.onToggleChapters,
  });

  final BookContent book;
  final String? activeChapterId;
  final bool singleActive;
  final bool busy;
  final ValueChanged<String> onOpen;
  final VoidCallback onOpenSingle;
  final void Function(BookChapter chapter, ChapterAction action) onAction;
  final VoidCallback onToggleChapters;

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
        child: book.chaptersEnabled
            ? ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: book.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = book.chapters[index];
                  return PlotcraftContextRegion<ChapterAction>(
                    itemsBuilder: (_) => _menu(index),
                    onSelected: (action) => onAction(chapter, action),
                    child: PanelListItem(
                      icon: Feather.file_text,
                      label: chapter.title,
                      selected: chapter.id == activeChapterId,
                      onTap: () => onOpen(chapter.id),
                      trailing: PlotcraftPopupMenuButton<ChapterAction>(
                        tooltip: 'book.chapter_actions'.tr(),
                        icon: const Icon(Feather.more_horizontal, size: 15),
                        onSelected: (action) => onAction(chapter, action),
                        itemBuilder: (_) => _menu(index),
                      ),
                    ),
                  );
                },
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  PanelListItem(
                    icon: Feather.file_text,
                    label: 'workspace.manuscript'.tr(),
                    selected: singleActive,
                    onTap: onOpenSingle,
                  ),
                ],
              ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: PlotcraftButton(
          icon: Feather.book_open,
          label: 'book.toggle_chapters'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: busy ? null : onToggleChapters,
        ),
      ),
    ],
  );
}
