import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String lang) {
  final json = jsonDecode(
    File('assets/translations/$lang.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Iterable<String> walk(String prefix, Map<String, dynamic> map) sync* {
    for (final entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map<String, dynamic>) {
        yield* walk(key, entry.value as Map<String, dynamic>);
      } else {
        yield key;
      }
    }
  }

  return walk('', json).toSet();
}

void main() {
  test('pt e en são JSON válidos com as mesmas chaves', () {
    final pt = _keys('pt');
    final en = _keys('en');
    expect(pt.difference(en), isEmpty, reason: 'faltam em en.json');
    expect(en.difference(pt), isEmpty, reason: 'faltam em pt.json');
  });
}
