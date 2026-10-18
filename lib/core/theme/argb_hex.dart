/// `#RRGGBB` for the ARGB value [argb] (alpha is not stored), the format used
/// in project files.
String argbToHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Parses `#RRGGBB` (the `#` is optional) into an opaque ARGB value; null when
/// it is not a color.
int? parseHexArgb(String? value) {
  if (value == null) return null;
  final hex = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return int.parse('FF$hex', radix: 16);
}
