import 'dart:io';

import 'package:plotcraft_mcp/src/tools/all.dart';
import 'package:test/test.dart';

void main() {
  test('o README descreve todas as ferramentas', () {
    final readme = File('README.md').readAsStringSync();
    final missing = [
      for (final tool in allTools())
        if (!readme.contains('`${tool.name}`')) tool.name,
    ];
    expect(missing, isEmpty, reason: 'rode: dart run tool/print_catalog.dart');
  });

  test('toda ferramenta tem nome snake_case, descrição e título em inglês', () {
    final names = <String>{};
    for (final tool in allTools()) {
      expect(tool.name, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
      expect(
        names.add(tool.name),
        isTrue,
        reason: 'nome repetido ${tool.name}',
      );
      expect(tool.description.length, greaterThan(20), reason: tool.name);
      expect(tool.title, isNotEmpty);
      // The server is in English: no Portuguese accents slipped in.
      expect(
        tool.description + tool.title,
        isNot(matches(RegExp('[ãõçáéíóúâêô]'))),
        reason: tool.name,
      );
    }
  });
}
