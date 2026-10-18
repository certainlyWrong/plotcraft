// Generates lib/core/icons/icon_catalog.g.dart from the icons_flutter package.
//
// icons_flutter has no name -> icon registry, so the picker needs a catalog.
// Every entry references the package's own `const IconData`, which keeps
// icon tree-shaking working and never builds an IconData from a code point.
//
// Run from the project root:  dart tool/gen_icon_catalog.dart
import 'dart:convert';
import 'dart:io';

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

  final out = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart tool/gen_icon_catalog.dart')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln()
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:icons_flutter/icons_flutter.dart';")
    ..writeln()
    ..writeln(
      '/// Set key (the icons_flutter class) -> label shown in the icon picker.',
    )
    ..writeln('const iconCatalogSets = <String, String>{');
  final body = StringBuffer()
    ..writeln('const iconCatalog = <String, Map<String, IconData>>{');
  var total = 0;
  _sets.forEach((file, label) {
    final source = File.fromUri(lib.resolve(file)).readAsStringSync();
    final className = RegExp(
      r'^class (\w+) \{',
      multiLine: true,
    ).firstMatch(source)!.group(1)!;
    final names = RegExp(r'static const IconData (\w+) =')
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();
    out.writeln("  '$className': '$label',");
    body.writeln("  '$className': {");
    for (final name in names) {
      body.writeln("    '$name': $className.$name,");
    }
    body.writeln('  },');
    total += names.length;
  });
  out
    ..writeln('};')
    ..writeln()
    ..writeln('/// $total icons.')
    ..write(body)
    ..writeln('};');
  File('lib/core/icons/icon_catalog.g.dart').writeAsStringSync(out.toString());
  stdout.writeln('Wrote $total icons from ${_sets.length} sets.');
}
