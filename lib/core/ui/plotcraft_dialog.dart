import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';
import 'gris/ink_stroke.dart';
import 'plotcraft_button.dart';

/// Shared dialog shell: a sheet of paper with a serif title and a brushed
/// stroke of ink beneath it. Title, body and action row styling come from the
/// active theme so every dialog in the app looks and reads the same.
class PlotcraftDialog extends StatelessWidget {
  const PlotcraftDialog({
    super.key,
    required this.title,
    required this.actions,
    this.content,
    this.maxWidth = 440,
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        // The content sets the width (up to its own cap); this only keeps a
        // short message from collapsing to the width of its title.
        constraints: const BoxConstraints(minWidth: 280),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
                child: Text(
                  title,
                  style: theme.dialogTheme.titleTextStyle,
                  semanticsLabel: title,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 6, 28, 0),
                child: InkStroke(width: 96),
              ),
              if (content != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: DefaultTextStyle(
                      style:
                          theme.dialogTheme.contentTextStyle ??
                          theme.textTheme.bodyMedium!,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: content,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for confirmation and resolves to `true` only when confirmed.
/// A destructive confirmation uses the error color for its action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => PlotcraftDialog(
      title: title,
      content: Text(message),
      actions: [
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
        ),
        PlotcraftButton(
          label: confirmLabel,
          variant: destructive
              ? PlotcraftButtonVariant.destructive
              : PlotcraftButtonVariant.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return confirmed == true;
}
