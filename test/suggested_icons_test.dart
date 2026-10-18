import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft_core/core/icons/suggested_icons.dart';

void main() {
  test('todo ícone sugerido existe no catálogo e aparece uma vez', () {
    final seen = <String>{};
    for (final group in suggestedIconGroups) {
      expect(group.icons, isNotEmpty, reason: group.id);
      for (final icon in group.icons) {
        expect(icon.exists, isTrue, reason: '$icon em ${group.id}');
        expect(seen.add('${icon.set}.${icon.name}'), isTrue, reason: '$icon');
      }
    }
  });

  test('todo grupo tem título em pt e en', () {
    for (final lang in ['pt', 'en']) {
      final json = jsonDecode(
        File('assets/translations/$lang.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final groups = (json['ui'] as Map)['icon_groups'] as Map;
      for (final group in suggestedIconGroups) {
        expect(groups[group.id], isA<String>(), reason: '$lang ${group.id}');
      }
    }
  });
}
