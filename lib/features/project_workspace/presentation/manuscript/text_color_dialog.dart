import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/theme/color_hex.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_color_picker.dart';
import '../../../../core/ui/plotcraft_dialog.dart';

/// Black and white, shown before the shared accent swatches.
const _textSwatches = <Color>[Color(0xFF000000), Color(0xFFFFFFFF)];

/// Picks the text or highlight color for the selection. Replaces the
/// toolbar's own dialog so it looks like the rest of the app.
Future<void> pickTextColor(
  BuildContext context,
  QuillController controller, {
  required bool background,
}) async {
  final attribute = background ? Attribute.background : Attribute.color;
  final current = parseHexColor(
    controller.getSelectionStyle().attributes[attribute.key]?.value as String?,
  );
  final result = await showDialog<_ColorChoice>(
    context: context,
    builder: (_) => _TextColorDialog(background: background, current: current),
  );
  if (result == null) return;
  final hex = result.clear ? null : colorToHex(result.color!);
  controller.formatSelection(
    background ? BackgroundAttribute(hex) : ColorAttribute(hex),
  );
}

class _ColorChoice {
  const _ColorChoice(this.color) : clear = false;
  const _ColorChoice.clear() : color = null, clear = true;

  final Color? color;
  final bool clear;
}

class _TextColorDialog extends StatefulWidget {
  const _TextColorDialog({required this.background, required this.current});

  final bool background;
  final Color? current;

  @override
  State<_TextColorDialog> createState() => _TextColorDialogState();
}

class _TextColorDialogState extends State<_TextColorDialog> {
  late Color? _color = widget.current;

  @override
  Widget build(BuildContext context) => PlotcraftDialog(
    title: (widget.background ? 'ui.highlight_color' : 'ui.text_color').tr(),
    maxWidth: 400,
    content: SizedBox(
      width: 400,
      child: PlotcraftColorPicker(
        color: _color,
        extraSwatches: _textSwatches,
        onChanged: (color) => setState(() => _color = color),
      ),
    ),
    actions: [
      if (widget.current != null)
        PlotcraftButton(
          label: 'ui.remove_color'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context, const _ColorChoice.clear()),
        ),
      PlotcraftButton(
        label: 'preferences.cancel'.tr(),
        variant: PlotcraftButtonVariant.text,
        onPressed: () => Navigator.pop(context),
      ),
      PlotcraftButton(
        label: 'ui.apply'.tr(),
        onPressed: _color == null
            ? null
            : () => Navigator.pop(context, _ColorChoice(_color)),
      ),
    ],
  );
}
