import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'plotcraft_button.dart';

/// Shared dialog shell. Title, body and action row styling come from the
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: content == null
        ? null
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          ),
    actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
    actions: actions,
  );
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
