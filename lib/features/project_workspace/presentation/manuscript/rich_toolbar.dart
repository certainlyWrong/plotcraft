import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import 'editor_fonts.dart';
import 'text_color_dialog.dart';

/// Toggled buttons get a soft tint with a readable icon, instead of the solid
/// primary fill of the default style.
QuillIconTheme _iconTheme(ColorScheme scheme) => QuillIconTheme(
  iconButtonUnselectedData: IconButtonData(
    color: scheme.onSurfaceVariant,
    disabledColor: scheme.onSurface.withValues(alpha: 0.38),
    highlightColor: scheme.onSurface.withValues(alpha: 0.08),
    hoverColor: scheme.onSurface.withValues(alpha: 0.08),
  ),
  iconButtonSelectedData: IconButtonData(
    color: scheme.onPrimaryContainer,
    style: IconButton.styleFrom(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      hoverColor: scheme.onPrimaryContainer.withValues(alpha: 0.08),
    ),
  ),
);

/// Formatting toolbar of the rich editor plus the document actions.
class RichToolbar extends StatelessWidget {
  const RichToolbar({
    super.key,
    required this.controller,
    required this.fullscreen,
    required this.findOpen,
    required this.onFind,
    required this.onToggleFullscreen,
    this.extraActions = const [],
    this.fonts = const {},
  });

  final QuillController controller;
  final bool fullscreen;
  final bool findOpen;
  final VoidCallback onFind;
  final VoidCallback onToggleFullscreen;

  /// Actions placed before find: linking elements, images, dividers.
  final List<Widget> extraActions;

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
                multiRowsDisplay: false,
                showListCheck: false,
                showLink: false,
                showDirection: false,
                showSmallButton: false,
                toolbarIconAlignment: WrapAlignment.start,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showInlineCode: false,
                showCodeBlock: false,
                color: Colors.transparent,
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: _iconTheme(scheme),
                  ),
                  fontFamily: QuillToolbarFontFamilyButtonOptions(
                    items: fonts,
                    tooltip: 'editor.font'.tr(),
                    defaultDisplayText: 'editor.font'.tr(),
                    defaultItemColor: scheme.onSurface,
                    renderFontFamilies: true,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  color: QuillToolbarColorButtonOptions(
                    customOnPressedCallback: (controller, background) =>
                        pickTextColor(context, controller, background: false),
                  ),
                  backgroundColor: QuillToolbarColorButtonOptions(
                    customOnPressedCallback: (controller, background) =>
                        pickTextColor(context, controller, background: true),
                  ),
                  fontSize: QuillToolbarFontSizeButtonOptions(
                    items: editorFontSizes,
                    tooltip: 'editor.size'.tr(),
                    defaultDisplayText: 'editor.size'.tr(),
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
                ...extraActions,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
