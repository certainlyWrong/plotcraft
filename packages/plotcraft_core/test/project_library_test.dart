import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  const library = ProjectLibrary();

  Future<String> makeProject(String name, String id, {String? title}) async {
    final folder = p.join(root.path, name);
    await Directory(folder).create(recursive: true);
    await File(p.join(folder, 'project.json')).writeAsString(
      '{"id":"$id","title":"${title ?? name}","schemaVersion":1,'
      '"createdAt":"2026-01-01T00:00:00.000Z",'
      '"updatedAt":"2026-01-01T00:00:00.000Z"}',
    );
    return folder;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plotcraft-library-');
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'encontra projetos na pasta raiz e ignora pastas sem manifesto',
    () async {
      await makeProject('um', '1');
      await makeProject('dois', '2');
      await Directory(p.join(root.path, 'solta')).create();
      await File(p.join(root.path, 'quebrado.json')).writeAsString('{');
      final broken = Directory(p.join(root.path, 'ruim'))..createSync();
      File(p.join(broken.path, 'project.json')).writeAsStringSync('{ not json');

      final found = await library.discover(root: root.path);
      expect(found.map((project) => project.id).toSet(), {'1', '2'});
      expect(found.every((project) => project.directoryPath != null), isTrue);
    },
  );

  test(
    'pastas conhecidas fora da raiz entram e o mesmo ID aparece uma vez',
    () async {
      final outside = await Directory.systemTemp.createTemp(
        'plotcraft-outside-',
      );
      addTearDown(() => outside.delete(recursive: true));
      File(p.join(outside.path, 'project.json')).writeAsStringSync(
        '{"id":"9","title":"Fora","schemaVersion":1,'
        '"createdAt":"2026-01-01T00:00:00.000Z",'
        '"updatedAt":"2026-01-01T00:00:00.000Z"}',
      );
      final inside = await makeProject('dentro', '1');

      final found = await library.discover(
        knownFolders: [outside.path, inside],
        root: root.path,
      );
      expect(found.map((project) => project.id).toSet(), {'1', '9'});
      expect(found, hasLength(2));
    },
  );

  test('excluir confere o manifesto e apaga a pasta', () async {
    final folder = await makeProject('apagar', '5');
    final project = (await library.read(folder))!;
    await library.delete(project);
    expect(Directory(folder).existsSync(), isFalse);

    final other = await makeProject('outro', '6');
    final real = (await library.read(other))!;
    final impostor = real.copyWith(title: 'Outro');
    File(p.join(other, 'project.json')).writeAsStringSync(
      '{"id":"7","title":"Trocado","schemaVersion":1,'
      '"createdAt":"2026-01-01T00:00:00.000Z",'
      '"updatedAt":"2026-01-01T00:00:00.000Z"}',
    );
    await expectLater(library.delete(impostor), throwsStateError);
    expect(Directory(other).existsSync(), isTrue);
  });
}
