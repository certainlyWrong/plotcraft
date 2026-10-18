import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/project_workspace/data/project_change_watcher.dart';

void main() {
  late Directory folder;
  late ProjectChangeWatcher watcher;
  late int events;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-watch-');
    await Directory(p.join(folder.path, 'content', 'book'))
        .create(recursive: true);
    events = 0;
    watcher = ProjectChangeWatcher(
      folder.path,
      debounce: const Duration(milliseconds: 150),
    )..start();
    watcher.changes.listen((_) => events++);
    // Let the OS register the watch before the test writes.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  tearDown(() async {
    watcher.dispose();
    await folder.delete(recursive: true);
  });

  test('uma rajada de gravações vira um único aviso', () async {
    final file = File(p.join(folder.path, 'content', 'book', 'a.delta.json'));
    for (var i = 0; i < 5; i++) {
      await file.writeAsString('{"i":$i}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // The OS may split a burst in two; five writes must not give five alerts.
    expect(events, inInclusiveRange(1, 2));
  });

  test(
    'arquivos temporários, arquivo morto e log do MCP são ignorados',
    () async {
      await File(p.join(folder.path, 'content', 'book', 'x.json.tmp'))
          .writeAsString('x');
      await Directory(p.join(folder.path, '.plotcraft')).create();
      await File(p.join(folder.path, '.plotcraft', 'mcp-log.jsonl'))
          .writeAsString('x');
      await Directory(p.join(folder.path, 'content', 'book', 'archive'))
          .create();
      await File(p.join(folder.path, 'content', 'book', 'archive', 'old.json'))
          .writeAsString('x');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(events, 0);
    },
  );
}
