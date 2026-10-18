import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_text_field.dart';

/// Dialog shared by sections and phases: a required title and a long text.
/// Resolves to `(title, body)` or null when cancelled.
Future<(String, String)?> showTitleBodyDialog(
  BuildContext context, {
  required String heading,
  required String titleLabel,
  required String bodyLabel,
  String title = '',
  String body = '',
  double width = 700,
  double bodyHeight = 260,
}) async {
  final titleController = TextEditingController(text: title);
  final bodyController = TextEditingController(text: body);
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => PlotcraftDialog(
      title: heading,
      maxWidth: width,
      content: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlotcraftTextField(
              controller: titleController,
              label: titleLabel,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: bodyHeight,
              child: PlotcraftTextField(
                controller: bodyController,
                label: bodyLabel,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
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
        PlotcraftButton(
          label: 'workspace.save_project'.tr(),
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;
            Navigator.pop(context, (
              titleController.text.trim(),
              bodyController.text,
            ));
          },
        ),
      ],
    ),
  );
  titleController.dispose();
  bodyController.dispose();
  return result;
}
