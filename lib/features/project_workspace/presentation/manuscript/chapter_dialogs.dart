import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_text_field.dart';

/// Asks for a chapter title; null when cancelled.
Future<String?> promptChapterTitle(
  BuildContext context, [
  String? current,
]) async {
  final controller = TextEditingController(text: current ?? '');
  final title = await showDialog<String>(
    context: context,
    builder: (context) => PlotcraftDialog(
      title: current == null ? 'book.add_chapter'.tr() : 'book.rename'.tr(),
      content: PlotcraftTextField(
        controller: controller,
        autofocus: true,
        label: 'book.chapter_title'.tr(),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
        },
      ),
      actions: [
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(
          label: 'ui.save'.tr(),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
        ),
      ],
    ),
  );
  controller.dispose();
  return title;
}
