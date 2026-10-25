import 'dart:io';

import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late String project;

  setUp(() async {
    h = await Harness.start();
    project = (await h.makeProject('Livro')).id;
  });
  tearDown(() => h.close());

  test('export_book writes each format into the project exports folder', () async {
    for (final format in ['epub', 'pdf', 'html']) {
      final result = (await h.call('export_book', {
        'project': project,
        'format': format,
      })).ok;
      final file = File(result['path']! as String);
      expect(file.existsSync(), isTrue, reason: format);
      expect(file.path, contains('/exports/'));
      expect(file.lengthSync(), result['bytes']);
    }
  });

  test('export_book rejects unknown formats and relative paths', () async {
    final bad = await h.call('export_book', {
      'project': project,
      'format': 'docx',
    });
    expect(bad.isError, isTrue);
    final relative = await h.call('export_book', {
      'project': project,
      'format': 'html',
      'output_path': 'book.html',
    });
    expect(relative.isError, isTrue);
  });
}
