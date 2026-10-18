import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_color_picker.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_icon_picker.dart';

/// The icon and color chosen for one element. Null means "use the type's".
class ElementAppearance {
  const ElementAppearance({this.icon, this.color});

  final IconRef? icon;
  final Color? color;
}

/// Lets the person override the icon and color an element takes from its
/// type. Resolves to the new appearance, or null if cancelled.
Future<ElementAppearance?> showElementAppearanceDialog(
  BuildContext context, {
  required ElementAppearance current,
  required IconRef typeIcon,
  required Color typeColor,
}) => showDialog<ElementAppearance>(
  context: context,
  builder: (_) => _AppearanceDialog(
    current: current,
    typeIcon: typeIcon,
    typeColor: typeColor,
  ),
);

class _AppearanceDialog extends StatefulWidget {
  const _AppearanceDialog({
    required this.current,
    required this.typeIcon,
    required this.typeColor,
  });

  final ElementAppearance current;
  final IconRef typeIcon;
  final Color typeColor;

  @override
  State<_AppearanceDialog> createState() => _AppearanceDialogState();
}

class _AppearanceDialogState extends State<_AppearanceDialog> {
  late IconRef? _icon = widget.current.icon;
  late Color? _color = widget.current.color;

  @override
  Widget build(BuildContext context) {
    final icon = _icon ?? widget.typeIcon;
    final color = _color ?? widget.typeColor;
    return PlotcraftDialog(
      title: 'elements.appearance'.tr(),
      maxWidth: 480,
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Tooltip(
                message: 'ui.icon_picker_title'.tr(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final picked = await showIconPicker(context, current: icon);
                    if (picked != null && mounted) {
                      setState(() => _icon = picked);
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon.data, size: 36, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PlotcraftColorPicker(
              color: color,
              onChanged: (picked) => setState(() => _color = picked),
            ),
          ],
        ),
      ),
      actions: [
        PlotcraftButton(
          label: 'elements.reset_appearance'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context, const ElementAppearance()),
        ),
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(
          label: 'workspace.save_project'.tr(),
          onPressed: () => Navigator.pop(
            context,
            ElementAppearance(icon: _icon, color: _color),
          ),
        ),
      ],
    );
  }
}
