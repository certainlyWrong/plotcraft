import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/project_workspace/data/narrative_repository.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_files.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late Directory outside;
  late StoryProject project;
  const repository = NarrativeRepository(ProjectFiles());

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-att-');
    outside = await Directory.systemTemp.createTemp('plotcraft-att-src-');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 'a1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"a1"}');
  });

  tearDown(() async {
    await folder.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  Future<String> source(String name, {int bytes = 4}) async {
    final file = File(p.join(outside.path, name));
    await file.writeAsBytes(List.filled(bytes, 7));
    return file.path;
  }

  NarrativeElement element(List<ElementImage> images) => NarrativeElement(
    id: 'maria',
    typeId: 'character',
    title: 'Maria',
    summary: '',
    sections: const [],
    phases: const [],
    images: images,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  test('copia a imagem para a pasta do elemento sem sobrescrever', () async {
    final first = await repository.attachImage(
      project,
      'maria',
      await source('foto.png'),
    );
    final second = await repository.attachImage(
      project,
      'maria',
      await source('foto.png'),
    );
    expect(first.isGallery, isFalse);
    expect(first.value, 'content/narrative/attachments/maria/foto.png');
    expect(second.value, 'content/narrative/attachments/maria/foto-2.png');
    expect(await File(p.join(folder.path, first.value)).readAsBytes(), [
      7,
      7,
      7,
      7,
    ]);
  });

  test(
    'recusa arquivos que não são imagem, ausentes, grandes ou IDs inválidos',
    () async {
      final text = File(p.join(outside.path, 'nota.txt'))
        ..writeAsStringSync('x');
      await expectLater(
        repository.attachImage(project, 'maria', text.path),
        throwsFormatException,
      );
      await expectLater(
        repository.attachImage(
          project,
          'maria',
          p.join(outside.path, 'nao_existe.png'),
        ),
        throwsFormatException,
      );
      await expectLater(
        repository.attachImage(
          project,
          'maria',
          await source('grande.png', bytes: 10 * 1024 * 1024 + 1),
        ),
        throwsFormatException,
      );
      await expectLater(
        repository.attachImage(project, '../fora', await source('a.png')),
        throwsFormatException,
      );
    },
  );

  test(
    'ao salvar, arquivos que o elemento deixou de usar são apagados',
    () async {
      final keep = await repository.attachImage(
        project,
        'maria',
        await source('a.png'),
      );
      final drop = await repository.attachImage(
        project,
        'maria',
        await source('b.png'),
      );
      await repository.saveElement(project, element([keep, drop]));
      expect(await File(p.join(folder.path, drop.value)).exists(), isTrue);

      await repository.saveElement(project, element([keep]));
      expect(await File(p.join(folder.path, keep.value)).exists(), isTrue);
      expect(await File(p.join(folder.path, drop.value)).exists(), isFalse);
    },
  );

  test('só resolve caminhos dentro da pasta de anexos', () {
    expect(
      repository.attachmentPath(
        project,
        'content/narrative/attachments/maria/a.png',
      ),
      p.join(
        folder.path,
        'content',
        'narrative',
        'attachments',
        'maria',
        'a.png',
      ),
    );
    expect(repository.attachmentPath(project, '../fora.png'), isNull);
    expect(repository.attachmentPath(project, 'project.json'), isNull);
    expect(
      repository.attachmentPath(
        project,
        'content/narrative/attachments/../../../project.json',
      ),
      isNull,
    );
  });
}
