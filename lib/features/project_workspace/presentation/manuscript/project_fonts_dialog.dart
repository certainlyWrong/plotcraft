import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../projects/domain/story_project.dart';
import '../../domain/project_font.dart';
import '../../stores/editor_fonts_store.dart';

/// Lists the fonts that belong to the project and lets the person add font
/// files to it or remove them. The files live in the project's `fonts/`
/// folder, so they go along when the project is copied to another computer.
Future<void> showProjectFontsDialog(
  BuildContext context, {
  required EditorFontsStore fonts,
  required StoryProject project,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ProjectFontsDialog(fonts: fonts, project: project),
);

class _ProjectFontsDialog extends StatelessWidget {
  const _ProjectFontsDialog({required this.fonts, required this.project});

  final EditorFontsStore fonts;
  final StoryProject project;

  Future<void> _add(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'editor.font_files'.tr(),
            extensions: const ['ttf', 'otf', 'ttc'],
          ),
        ],
      );
      if (files.isEmpty) return;
      final added = await fonts.add(
        project,
        files.map((file) => file.path).toList(),
      );
      if (added.length < files.length) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'editor.fonts_skipped'.tr(
                namedArgs: {'count': '${files.length - added.length}'},
              ),
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('editor.fonts_error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlotcraftDialog(
      title: 'editor.project_fonts'.tr(),
      maxWidth: 520,
      content: SizedBox(
        width: 520,
        height: 320,
        child: Observer(
          builder: (_) {
            final list = fonts.projectFonts.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'editor.project_fonts_help'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: list.isEmpty
                      ? Center(child: Text('editor.no_project_fonts'.tr()))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) =>
                              _row(context, list[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        PlotcraftButton(
          icon: Feather.plus,
          label: 'editor.add_fonts'.tr(),
          variant: PlotcraftButtonVariant.secondary,
          onPressed: () => _add(context),
        ),
        PlotcraftButton(
          label: 'editor.close'.tr(),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, ProjectFont font) => ListTile(
    dense: true,
    leading: const Icon(Feather.type, size: 18),
    title: Text(
      font.family,
      style: TextStyle(fontFamily: fonts.catalog.registeredName(font.family)),
    ),
    subtitle: Text(
      font.style.isEmpty ? font.file : '${font.style} · ${font.file}',
    ),
    trailing: PlotcraftIconButton(
      icon: Feather.trash_2,
      tooltip: 'elements.remove'.tr(),
      onPressed: () => fonts.remove(project, font),
    ),
  );
}
