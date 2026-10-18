import 'dart:ui';

import 'package:plotcraft_core/core/theme/argb_hex.dart';

/// `#RRGGBB` for [color], the format used in project files.
String colorToHex(Color color) => argbToHex(color.toARGB32());

/// Parses `#RRGGBB` (the `#` is optional); null when it is not a color.
Color? parseHexColor(String? value) {
  final argb = parseHexArgb(value);
  return argb == null ? null : Color(argb);
}
