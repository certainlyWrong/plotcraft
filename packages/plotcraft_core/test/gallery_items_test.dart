import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/project_workspace/data/gallery_repository.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_files.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late Directory outside;
  late StoryProject project;
  const repository = GalleryRepository(ProjectFiles());

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-gal-');
    outside = await Directory.systemTemp.createTemp('plotcraft-src-');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 'g1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"g1"}');
  });

  tearDown(() async {
    await folder.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  Future<String> source(String name) async {
    final file = File(p.join(outside.path, name));
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  Future<void> addByHand(String name) =>
      File(p.join(folder.path, 'gallery', name))
          .create(recursive: true)
          .then((file) => file.writeAsBytes([9]));

  test('imagens importadas recebem IDs que não mudam entre leituras', () async {
    final result = await repository.importImages(project, [
      await source('a.png'),
      await source('b.jpg'),
    ]);
    expect(result.items.map((item) => item.file), ['a.png', 'b.jpg']);
    final ids = result.items.map((item) => item.id).toList();
    expect(ids.toSet().length, 2);
    expect(ids, everyElement(startsWith('g_')));

    final again = await repository.items(result.project);
    expect(again.map((item) => item.id), ids);
  });

  test(
    'arquivo colocado na pasta à mão ganha ID e os existentes são mantidos',
    () async {
      final first = await repository.importImages(project, [
        await source('a.png'),
      ]);
      final idOfA = first.items.single.id;
      await addByHand('manual.webp');
      final items = await repository.items(first.project);
      expect(items.map((item) => item.file), ['a.png', 'manual.webp']);
      expect(items.first.id, idOfA);
      expect(items.every((item) => item.exists), isTrue);
    },
  );

  test(
    'arquivo apagado por fora fica marcado como ausente e volta com o mesmo ID',
    () async {
      final first = await repository.importImages(project, [
        await source('a.png'),
      ]);
      final item = first.items.single;
      await File(item.path).delete();

      final missing = (await repository.items(first.project)).single;
      expect(missing.id, item.id);
      expect(missing.exists, isFalse);
      expect(await repository.list(first.project), isEmpty);

      await addByHand('a.png');
      final back = (await repository.items(first.project)).single;
      expect(back.id, item.id);
      expect(back.exists, isTrue);
    },
  );

  test('remover pelo app apaga também a entrada do índice', () async {
    final first = await repository.importImages(project, [
      await source('a.png'),
      await source('b.png'),
    ]);
    final removed = await repository.removeImage(
      first.project,
      first.images.first,
    );
    expect(removed.items.map((item) => item.file), ['b.png']);

    final index = jsonDecode(
      await File(p.join(folder.path, 'gallery', 'index.json')).readAsString(),
    ) as Map<String, dynamic>;
    expect((index['items'] as List).map((e) => (e as Map)['file']), ['b.png']);
  });

  test('índice corrompido é refeito sem perder as imagens', () async {
    await addByHand('a.png');
    await File(p.join(folder.path, 'gallery', 'index.json'))
        .writeAsString('{ quebrado');
    final items = await repository.items(project);
    expect(items.single.file, 'a.png');
    expect(items.single.id, startsWith('g_'));
  });
}
