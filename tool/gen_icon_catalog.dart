// Generates the icon catalog from the icons_flutter package:
//   lib/core/icons/icon_names.g.dart    set labels and icon names (pure Dart)
//   lib/core/icons/icon_catalog.g.dart  name -> IconData (needs Flutter)
//
// icons_flutter has no name -> icon registry, so the picker needs a catalog.
// Every entry references the package's own `const IconData`, which keeps
// icon tree-shaking working and never builds an IconData from a code point.
//
// Some constants of the package point to code points that their font does not
// contain; the release build's font subsetter aborts on those. The script
// reads each font's character map and leaves such icons out.
//
// Run from the project root:  dart tool/gen_icon_catalog.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Package source file -> label shown in the icon picker.
const _sets = <String, String>{
  'feather.dart': 'Feather',
  'material_community_icons.dart': 'Material Design',
  'material_icons.dart': 'Material',
  'font_awesome_5_solid.dart': 'Font Awesome',
  'rpg_awesome_icons.dart': 'RPG',
  'ionicons.dart': 'Ionicons',
  'entypo.dart': 'Entypo',
};

void main() {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final package = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'icons_flutter');
  var rootUri = Uri.parse(package['rootUri'] as String);
  if (!rootUri.path.endsWith('/')) {
    rootUri = rootUri.replace(path: '${rootUri.path}/');
  }
  final root = rootUri.isAbsolute
      ? rootUri
      : Directory('.dart_tool').absolute.uri.resolveUri(rootUri);
  final lib = root.resolve('lib/src/');

  final names = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart tool/gen_icon_catalog.dart')
    ..writeln()
    ..writeln(
      '/// Set key (the icons_flutter class) -> label shown in the icon picker.',
    )
    ..writeln('const iconCatalogSets = <String, String>{');
  final namesBody = StringBuffer()
    ..writeln('/// Icon names of each set, in the order of the package.')
    ..writeln('const iconNames = <String, List<String>>{');
  final out = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart tool/gen_icon_catalog.dart')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln()
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:icons_flutter/icons_flutter.dart';")
    ..writeln();
  final body = StringBuffer()
    ..writeln('const iconCatalog = <String, Map<String, IconData>>{');
  var total = 0;
  var skipped = 0;
  _sets.forEach((file, label) {
    final source = File.fromUri(lib.resolve(file)).readAsStringSync();
    final className = RegExp(
      r'^class (\w+) \{',
      multiLine: true,
    ).firstMatch(source)!.group(1)!;
    final family = RegExp(r'static const String _family = "([^"]+)"')
        .firstMatch(source)!
        .group(1)!;
    final glyphs = _codePoints(
      File.fromUri(root.resolve('fonts/$family.ttf')).readAsBytesSync(),
    );
    names.writeln("  '$className': '$label',");
    namesBody.writeln("  '$className': [");
    body.writeln("  '$className': {");
    for (final match in RegExp(
      r'static const IconData (\w+) = IconData\((0x[0-9a-fA-F]+|\d+),',
    ).allMatches(source)) {
      final name = match.group(1)!;
      if (!glyphs.contains(int.parse(match.group(2)!))) {
        skipped++;
        stdout.writeln('Skipping $className.$name: not in the $family font.');
        continue;
      }
      namesBody.writeln("    '$name',");
      body.writeln("    '$name': $className.$name,");
      total++;
    }
    namesBody.writeln('  ],');
    body.writeln('  },');
  });
  names
    ..writeln('};')
    ..writeln()
    ..write(namesBody)
    ..writeln('};');
  out
    ..writeln('/// $total icons.')
    ..write(body)
    ..writeln('};');
  File('lib/core/icons/icon_names.g.dart').writeAsStringSync(names.toString());
  File('lib/core/icons/icon_catalog.g.dart').writeAsStringSync(out.toString());
  stdout.writeln(
    'Wrote $total icons from ${_sets.length} sets ($skipped skipped).',
  );
}

/// Code points that map to a real glyph in a TrueType font (cmap formats 4
/// and 12, which cover every font in the package).
Set<int> _codePoints(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final tables = data.getUint16(4);
  int? cmap;
  for (var i = 0; i < tables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
    if (tag == 'cmap') cmap = data.getUint32(record + 8);
  }
  if (cmap == null) throw StateError('Font without a cmap table');
  final result = <int>{};
  final subtables = data.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final start = cmap + data.getUint32(cmap + 4 + i * 8 + 4);
    switch (data.getUint16(start)) {
      case 4:
        _format4(data, start, result);
      case 12:
        _format12(data, start, result);
    }
  }
  return result;
}

void _format4(ByteData data, int start, Set<int> result) {
  final segments = data.getUint16(start + 6) ~/ 2;
  final ends = start + 14;
  final starts = ends + segments * 2 + 2;
  final deltas = starts + segments * 2;
  final offsets = deltas + segments * 2;
  for (var s = 0; s < segments; s++) {
    final first = data.getUint16(starts + s * 2);
    final last = data.getUint16(ends + s * 2);
    final delta = data.getInt16(deltas + s * 2);
    final rangeOffset = data.getUint16(offsets + s * 2);
    for (var c = first; c <= last && c != 0xFFFF; c++) {
      int glyph;
      if (rangeOffset == 0) {
        glyph = (c + delta) & 0xFFFF;
      } else {
        final at = offsets + s * 2 + rangeOffset + (c - first) * 2;
        if (at + 2 > data.lengthInBytes) continue;
        glyph = data.getUint16(at);
        if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
      }
      if (glyph != 0) result.add(c);
    }
  }
}

void _format12(ByteData data, int start, Set<int> result) {
  final groups = data.getUint32(start + 12);
  for (var g = 0; g < groups; g++) {
    final at = start + 16 + g * 12;
    final first = data.getUint32(at);
    final last = data.getUint32(at + 4);
    final glyph = data.getUint32(at + 8);
    for (var c = first; c <= last; c++) {
      if (glyph + (c - first) != 0) result.add(c);
    }
  }
}
