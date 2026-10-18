import 'dart:convert';
import 'dart:typed_data';

/// What the app needs to know about a font file: the family it belongs to.
class FontFileInfo {
  const FontFileInfo({required this.family, this.style = ''});

  final String family;

  /// The style name ("Regular", "Bold Italic"), when the file has one.
  final String style;

  /// Reads the family of a TrueType or OpenType font (also `.ttc`
  /// collections, using their first font). Returns null for anything else.
  static FontFileInfo? read(Uint8List bytes) {
    try {
      return _read(bytes);
    } on RangeError {
      return null;
    }
  }

  static FontFileInfo? _read(Uint8List bytes) {
    if (bytes.length < 12) return null;
    final data = ByteData.sublistView(bytes);
    var base = 0;
    var tag = String.fromCharCodes(bytes.sublist(0, 4));
    if (tag == 'ttcf') {
      // A collection: the offset of the first font follows the header.
      base = data.getUint32(12);
      tag = String.fromCharCodes(bytes.sublist(base, base + 4));
    }
    const known = {'true', 'OTTO', '\u0000\u0001\u0000\u0000', 'typ1'};
    if (!known.contains(tag)) return null;
    final tables = data.getUint16(base + 4);
    int? nameTable;
    for (var i = 0; i < tables; i++) {
      final record = base + 12 + i * 16;
      final name = String.fromCharCodes(bytes.sublist(record, record + 4));
      if (name == 'name') nameTable = data.getUint32(record + 8);
    }
    if (nameTable == null) return null;
    final count = data.getUint16(nameTable + 2);
    final stringsAt = nameTable + data.getUint16(nameTable + 4);
    final names = <int, String>{};
    for (var i = 0; i < count; i++) {
      final record = nameTable + 6 + i * 12;
      final platform = data.getUint16(record);
      final id = data.getUint16(record + 6);
      final length = data.getUint16(record + 8);
      final offset = data.getUint16(record + 10);
      if (names.containsKey(id) && platform == 1) continue; // keep Unicode
      final raw = bytes.sublist(
        stringsAt + offset,
        stringsAt + offset + length,
      );
      final text = platform == 1 ? latin1.decode(raw) : _utf16(raw);
      if (text.trim().isNotEmpty) names[id] = text.trim();
    }
    // 16/17 are the family and style without the 4-style naming limit.
    final family = names[16] ?? names[1];
    if (family == null) return null;
    return FontFileInfo(family: family, style: names[17] ?? names[2] ?? '');
  }

  static String _utf16(Uint8List raw) {
    final units = <int>[
      for (var i = 0; i + 1 < raw.length; i += 2) (raw[i] << 8) | raw[i + 1],
    ];
    return String.fromCharCodes(units);
  }
}
