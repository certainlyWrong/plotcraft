import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/projects/data/library_watcher.dart';

void main() {
  late Directory root;
  late LibraryWatcher watcher;
  late int events;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plotcraft-library-watch-');
    events = 0;
    watcher = LibraryWatcher(
      root.path,
      debounce: const Duration(milliseconds: 150),
    )..start();
    watcher.changes.listen((_) => events++);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  tearDown(() async {
    watcher.dispose();
    await root.delete(recursive: true);
  });

  test('um projeto novo (pasta e manifesto) avisa a biblioteca', () async {
    final folder = Directory(p.join(root.path, 'novo-1'))..createSync();
    File(p.join(folder.path, 'project.json')).writeAsStringSync('{}');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(events, inInclusiveRange(1, 2));
  });

  test(
    'o conteúdo de dentro do projeto e as pastas ocultas não avisam',
    () async {
      final folder = Directory(p.join(root.path, 'existente'))..createSync();
      File(p.join(folder.path, 'project.json')).writeAsStringSync('{}');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final before = events;
      final deep = Directory(p.join(folder.path, 'content', 'book'))
        ..createSync(recursive: true);
      File(p.join(deep.path, 'a.delta.json')).writeAsStringSync('x');
      Directory(p.join(root.path, '.plotcraft')).createSync();
      File(p.join(root.path, '.plotcraft', 'app.json')).writeAsStringSync('x');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(events, before);
    },
  );
}
