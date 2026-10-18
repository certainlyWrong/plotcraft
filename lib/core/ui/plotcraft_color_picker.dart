import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../theme/color_hex.dart';
import '../theme/plotcraft_tokens.dart';
import 'plotcraft_text_field.dart';

/// Swatches offered for element types and highlights.
const plotcraftSwatches = <Color>[
  Color(0xFFB86D52),
  Color(0xFFD9822B),
  Color(0xFFC9A227),
  Color(0xFF7C9A3C),
  Color(0xFF3E9B6B),
  Color(0xFF2E9AA3),
  Color(0xFF3B7DBF),
  Color(0xFF5B5FC7),
  Color(0xFF7B5EA7),
  Color(0xFFA855A0),
  Color(0xFFC4506F),
  Color(0xFFC0443F),
  Color(0xFF8A6A4F),
  Color(0xFF6B7280),
  Color(0xFF3F4756),
  Color(0xFF1F2430),
];

/// Row of swatches plus a hex field. Reports valid colors only.
class PlotcraftColorPicker extends StatefulWidget {
  const PlotcraftColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.extraSwatches = const [],
  });

  final Color? color;

  /// Swatches shown before the shared ones.
  final List<Color> extraSwatches;
  final ValueChanged<Color> onChanged;

  @override
  State<PlotcraftColorPicker> createState() => _PlotcraftColorPickerState();
}

class _PlotcraftColorPickerState extends State<PlotcraftColorPicker> {
  late final _hex = TextEditingController(
    text: widget.color == null ? '' : colorToHex(widget.color!),
  );

  @override
  void didUpdateWidget(covariant PlotcraftColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final color = widget.color;
    if (color != null && parseHexColor(_hex.text) != color) {
      _hex.text = colorToHex(color);
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final swatch in [...widget.extraSwatches, ...plotcraftSwatches])
            _Swatch(
              color: swatch,
              selected: swatch == widget.color,
              onTap: () => widget.onChanged(swatch),
            ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: 160,
        child: PlotcraftTextField(
          controller: _hex,
          compact: true,
          hint: 'ui.color_picker_hex'.tr(),
          onChanged: (value) {
            final color = parseHexColor(value);
            if (color != null) widget.onChanged(color);
          },
        ),
      ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(PlotcraftRadii.control),
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(
              Feather.check,
              size: 15,
              color: context.tokens.onSwatch([color]),
            )
          : null,
    ),
  );
}
