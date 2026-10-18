import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import 'editor_fonts.dart';

/// Formatting toolbar of the rich editor plus the document actions.
class RichToolbar extends StatelessWidget {
  const RichToolbar({
    super.key,
    required this.controller,
    required this.fullscreen,
    required this.canSave,
    required this.findOpen,
    required this.onFind,
    required this.onToggleFullscreen,
    required this.onSave,
    this.fonts = bundledEditorFonts,
  });

  final QuillController controller;
  final bool fullscreen;
  final bool canSave;
  final bool findOpen;
  final VoidCallback onFind;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onSave;

  /// Display name -> family for the font menu.
  final Map<String, String> fonts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: QuillSimpleToolbar(
              controller: controller,
              config: QuillSimpleToolbarConfig(
                multiRowsDisplay: true,
                toolbarRunSpacing: 0,
                toolbarIconAlignment: WrapAlignment.start,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showInlineCode: true,
                showCodeBlock: true,
                showListCheck: true,
                color: Colors.transparent,
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  fontFamily: QuillToolbarFontFamilyButtonOptions(
                    items: fonts,
                    tooltip: 'editor.font'.tr(),
                    defaultItemColor: scheme.onSurface,
                    renderFontFamilies: true,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  fontSize: QuillToolbarFontSizeButtonOptions(
                    items: editorFontSizes,
                    tooltip: 'editor.size'.tr(),
                    defaultItemColor: scheme.onSurface,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlotcraftIconButton(
                  icon: Feather.search,
                  tooltip: 'book.find'.tr(),
                  onPressed: onFind,
                ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
