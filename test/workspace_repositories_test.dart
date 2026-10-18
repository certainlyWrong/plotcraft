import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/projects/domain/cover_image_rules.dart';
import 'package:plotcraft/features/projects/domain/project_metadata_input.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late Directory outside;
  late StoryProject project;
  final repository = ProjectWorkspaceRepository();

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-project-');
    outside = await Directory.systemTemp.createTemp('plotcraft-outside-');
    final now = DateTime.utc(2026, 1, 1);
    project = StoryProject(
      id: 'p1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"p1"}');
  });

  tearDown(() async {
    for (final directory in [folder, outside]) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });

  Future<String> image(String name, {int bytes = 4}) async {
    final file = File(p.join(outside.path, name));
    await file.writeAsBytes(List.filled(bytes, 1));
    return file.path;
  }

  test(
    'galeria importa sem sobrescrever nomes e remove com segurança',
    () async {
      final first = await image('foto.png');
      final imported = await repository.gallery.importImages(project, [first]);
      final again = await repository.gallery.importImages(imported.project, [
        first,
      ]);
      expect(again.images.map(p.basename), ['foto-2.png', 'foto.png']);

      final removed = await repository.gallery.removeImage(
        again.project,
        again.images.first,
      );
      expect(removed.images.map(p.basename), ['foto.png']);
      expect(
        (await repository.load(removed.project)).galleryImages,
        removed.images,
      );
    },
  );

  test(
    'galeria rejeita arquivos que não são imagens e caminhos externos',
    () async {
      final text = File(p.join(outside.path, 'nota.txt'))
        ..writeAsStringSync('x');
      await expectLater(
        repository.gallery.importImages(project, [text.path]),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        repository.gallery.removeImage(project, await image('fora.png')),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('atualiza metadados, troca a capa e apaga a capa antiga', () async {
    ProjectMetadataInput input(String? cover) => ProjectMetadataInput(
      title: 'Novo título',
      subtitle: '',
      author: 'Autora',
      description: '',
      genre: '',
      tags: const ['a', 'b'],
      coverIndex: 1,
      coverSourcePath: cover,
    );
    final withCover = await repository.metadata.updateMetadata(
      project,
      input(await image('capa.jpg')),
      removeCover: false,
    );
    expect(withCover.title, 'Novo título');
    final oldCover = File(p.join(folder.path, withCover.coverFile!));
    expect(await oldCover.exists(), isTrue);

    final removed = await repository.metadata.updateMetadata(
      withCover,
      input(null),
      removeCover: true,
    );
    expect(removed.coverFile, isNull);
    expect(await oldCover.exists(), isFalse);
  });

  test('regras de capa e validação dos metadados', () async {
    expect(await CoverImageRules.isValid(await image('ok.webp')), isTrue);
    expect(await CoverImageRules.isValid(await image('ruim.gif')), isFalse);
    expect(
      await CoverImageRules.isValid(
        await image('grande.png', bytes: CoverImageRules.maxBytes + 1),
      ),
      isFalse,
    );
    expect(
      await CoverImageRules.isValid(p.join(outside.path, 'x.png')),
      isFalse,
    );

    expect(
      ProjectMetadataInput.validateTitle('ab'),
      ProjectFieldIssue.tooShort,
    );
    expect(
      ProjectMetadataInput.validateTitle('  '),
      ProjectFieldIssue.required,
    );
    expect(
      ProjectMetadataInput.validateTags(['a', 'A']),
      ProjectFieldIssue.duplicated,
    );
    expect(ProjectMetadataInput.parseTags(' a, ,b '), ['a', 'b']);
  });
}
