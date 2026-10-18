import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft/features/project_workspace/domain/markdown_extensions.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late StoryProject project;
  final repository = ProjectWorkspaceRepository();

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-book-');
    final now = DateTime.utc(2026, 1, 1);
    project = StoryProject(
      id: 'test-book',
      title: 'A história',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"test-book"}');
    final manuscript = File(
      p.join(folder.path, 'content', 'book', 'manuscript.md'),
    );
    await manuscript.parent.create(recursive: true);
    await manuscript.writeAsString('# A história\n\nTexto original.');
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  test(
    'converte manuscrito legado em capítulos e de volta sem perder texto',
    () async {
      final legacy = await repository.load(project);
      expect(legacy.book.chaptersEnabled, isFalse);
      expect(legacy.book.singleText, contains('Texto original.'));

      final divided = await repository.setChapterMode(
        project,
        legacy.book,
        true,
      );
      expect(divided.book.chaptersEnabled, isTrue);
      expect(divided.book.chapters, hasLength(1));
      expect(divided.book.combinedText, contains('Texto original.'));

      final added = await repository.addChapter(
        divided.project,
        divided.book,
        'Capítulo dois',
      );
      final secondId = added.book.chapters.last.id;
      final saved = await repository.saveBookDocument(
        added.project,
        added.book,
        secondId,
        'Uma nova cena.',
      );
      expect(saved.book.combinedText, contains('Uma nova cena.'));

      final reordered = await repository.updateChapters(
        saved.project,
        saved.book,
        saved.book.chapters.reversed.toList(),
      );
      expect(reordered.book.chapters.first.id, secondId);

      final joined = await repository.setChapterMode(
        reordered.project,
        reordered.book,
        false,
      );
      expect(joined.book.singleText, contains('Texto original.'));
      expect(joined.book.singleText, contains('Uma nova cena.'));
      expect(
        await File(
          p.join(folder.path, 'content', 'book', 'chapters', '$secondId.md'),
        ).exists(),
        isTrue,
      );
      final reopened = await repository.load(joined.project);
      expect(reopened.book.chaptersEnabled, isFalse);
      expect(reopened.book.singleText, joined.book.singleText);
    },
  );

  test('persiste elementos e mantém referências por ID', () async {
    final now = DateTime.utc(2026, 1, 1);
    final element = NarrativeElement(
      id: 'personagem_1',
      kind: 'character',
      title: 'Lia',
      summary: 'Protagonista',
      sections: const [
        NarrativeSection(
          id: 'historia',
          title: 'História',
          markdown: 'Sua origem.',
        ),
      ],
      phases: const [
        NarrativePhase(
          id: 'inicio',
          title: 'Início',
          description: 'Ainda insegura.',
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    final (updated, _) = await repository.saveElement(project, element);
    final reopened = await repository.load(updated);
    expect(reopened.elements.single.sections.single.markdown, 'Sua origem.');
    expect(reopened.elements.single.phases.single.title, 'Início');

    final marker = NarrativeLinkExtension.marker(element);
    expect(
      NarrativeLinkExtension.references('Encontrei $marker.', element.id),
      isTrue,
    );
    final renamed = element.copyWith(title: 'Lia de Sal');
    final preview = NarrativeLinkExtension([renamed])
        .preparePreview('Encontrei $marker.');
    expect(preview, contains('plotcraft://element/personagem_1'));

    await repository.removeElement(updated, element.id);
    expect((await repository.load(updated)).elements, isEmpty);
    expect(
      await File(
        p.join(
          folder.path,
          'content',
          'narrative',
          'archive',
          'personagem_1.json',
        ),
      ).exists(),
      isTrue,
    );
  });

  test('não permite reordenar perdendo capítulos', () async {
    final initial = await repository.load(project);
    final divided = await repository.setChapterMode(
      project,
      initial.book,
      true,
    );
    final added = await repository.addChapter(
      divided.project,
      divided.book,
      'Segundo',
    );
    await expectLater(
      repository.updateChapters(added.project, added.book, [
        added.book.chapters.first,
      ]),
      throwsA(isA<FormatException>()),
    );
    expect(added.book, isA<BookContent>());
  });
}
