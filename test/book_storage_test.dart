import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late StoryProject project;
  late String book;
  final repository = ProjectWorkspaceRepository();

  Future<void> write(String relative, String content) async {
    final file = File(p.join(folder.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<String> read(String relative) =>
      File(p.join(folder.path, relative)).readAsString();

  Future<bool> exists(String relative) =>
      File(p.join(folder.path, relative)).exists();

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-bookstore-');
    book = p.join('content', 'book');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 'bs1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await write('project.json', '{"id":"bs1"}');
  });

  tearDown(() => folder.delete(recursive: true));

  test(
    'um manuscrito só com Markdown é convertido, salvo como Delta e copiado',
    () async {
      await write(
        '$book/manuscript.md',
        '# A história\n\nTexto com **negrito** e [[element:lia|Lia]].\n',
      );

      final loaded = await repository.load(project);
      final delta = loaded.book.singleDelta;
      expect(
        RichDocument.plainText(delta),
        'A história\nTexto com negrito e Lia.\n',
      );
      expect(RichDocument.mentionedIds(delta), ['lia']);

      // The original Markdown is backed up before anything else is written.
      expect(
        await read('$book/migration-backup/manuscript.md'),
        '# A história\n\nTexto com **negrito** e [[element:lia|Lia]].\n',
      );
      final saved = jsonDecode(
        await read('$book/manuscript.delta.json'),
      ) as Map<String, dynamic>;
      expect(saved['schemaVersion'], 1);
      expect(
        Delta.fromJson(saved['ops'] as List<dynamic>).toJson(),
        delta.toJson(),
      );
      // The Markdown file is left as the person wrote it until the next save.
      expect(await read('$book/manuscript.md'), startsWith('# A história'));
    },
  );

  test('a migração é idempotente e não sobrescreve o backup', () async {
    await write('$book/manuscript.md', 'Original.\n');
    await repository.load(project);
    // A later edit of the Markdown (outside the app) does not touch the backup.
    await write('$book/manuscript.md', 'Mudou fora.\n');
    final again = await repository.load(project);
    expect(await read('$book/migration-backup/manuscript.md'), 'Original.\n');
    // The Delta already exists, so it is the truth now.
    expect(RichDocument.plainText(again.book.singleDelta), 'Original.\n');
  });

  test('salvar grava o Delta e a cópia em Markdown', () async {
    await write('$book/manuscript.md', 'x\n');
    final loaded = await repository.load(project);
    final delta = Delta()
      ..insert('Título')
      ..insert('\n', {'header': 2})
      ..insert('forte', {'bold': true, 'color': '#ff0000'})
      ..insert(' e comum.\n');
    final result = await repository.book.saveBookDocument(
      project,
      loaded.book,
      null,
      delta,
    );
    expect(result.book.singleDelta.toJson(), delta.toJson());
    expect(
      await read('$book/manuscript.md'),
      '## Título\n\n**forte** e comum.\n',
    );
    final json = jsonDecode(
      await read('$book/manuscript.delta.json'),
    ) as Map<String, dynamic>;
    // Colors survive in the Delta even though the Markdown cannot hold them.
    expect(jsonEncode(json['ops']), contains('#ff0000'));
  });

  test('Delta corrompido cai de volta no Markdown sem apagar nada', () async {
    await write('$book/manuscript.md', 'Salvo no Markdown.\n');
    await write('$book/manuscript.delta.json', '{ quebrado');
    final loaded = await repository.load(project);
    expect(
      RichDocument.plainText(loaded.book.singleDelta),
      'Salvo no Markdown.\n',
    );
    // The damaged file is kept for recovery.
    expect(await read('$book/manuscript.delta.json'), '{ quebrado');
  });

  test('Delta corrompido sem Markdown abre vazio', () async {
    await write('$book/manuscript.delta.json', '[]');
    final loaded = await repository.load(project);
    expect(RichDocument.plainText(loaded.book.singleDelta), '\n');
  });

  test(
    'capítulos: cada um migra com o seu backup e a ordem é mantida',
    () async {
      await write(
        '$book/book.json',
        jsonEncode({
          'schemaVersion': 1,
          'mode': 'chapters',
          'chapters': [
            {'id': 'c1', 'title': 'Um'},
            {'id': 'c2', 'title': 'Dois'},
          ],
        }),
      );
      await write('$book/chapters/c1.md', 'Primeiro.\n');
      await write('$book/chapters/c2.md', '## Segundo\n');
      final loaded = await repository.load(project);
      expect(loaded.book.chaptersEnabled, isTrue);
      expect(loaded.book.textFor('c1').trim(), 'Primeiro.');
      expect(loaded.book.textFor('c2').trim(), 'Segundo');
      expect(await exists('$book/migration-backup/c1.md'), isTrue);
      expect(await exists('$book/migration-backup/c2.md'), isTrue);
      expect(await exists('$book/chapters/c1.delta.json'), isTrue);
    },
  );

  test('remover um capítulo arquiva o Delta e o Markdown', () async {
    await write(
      '$book/book.json',
      jsonEncode({
        'mode': 'chapters',
        'chapters': [
          {'id': 'c1', 'title': 'Um'},
          {'id': 'c2', 'title': 'Dois'},
        ],
      }),
    );
    await write('$book/chapters/c1.md', 'a\n');
    await write('$book/chapters/c2.md', 'b\n');
    final loaded = await repository.load(project);
    await repository.book.removeChapter(project, loaded.book, 'c2');
    expect(await exists('$book/chapters/c2.md'), isFalse);
    expect(await exists('$book/chapters/c2.delta.json'), isFalse);
    expect(await exists('$book/archive/c2.md'), isTrue);
    expect(await exists('$book/archive/c2.delta.json'), isTrue);
  });

  test(
    'juntar capítulos põe o título de cada um, sem duplicar o que já tem',
    () async {
      await write(
        '$book/book.json',
        jsonEncode({
          'mode': 'chapters',
          'chapters': [
            {'id': 'c1', 'title': 'Um'},
            {'id': 'c2', 'title': 'Dois'},
          ],
        }),
      );
      await write('$book/chapters/c1.md', '# Um\n\nJá tem título.\n');
      await write('$book/chapters/c2.md', 'Sem título.\n');
      final loaded = await repository.load(project);
      final joined = await repository.book.setChapterMode(
        project,
        loaded.book,
        false,
      );
      expect(
        RichDocument.plainText(joined.book.singleDelta),
        'Um\nJá tem título.\nDois\nSem título.\n',
      );
      expect(
        await read('$book/manuscript.md'),
        '# Um\n\nJá tem título.\n\n# Dois\n\nSem título.\n',
      );
    },
  );

  test('imagens da galeria saem do Markdown com o nome do arquivo e voltam como ID', () async {
    await write('gallery/foto da pista.png', 'x');
    final items = await repository.gallery.items(project);
    final id = items.single.id;
    final loaded = await repository.load(project);
    final delta = Delta()
      ..insert(RichDocument.galleryImage(id))
      ..insert('\n');
    await repository.book.saveBookDocument(project, loaded.book, null, delta);
    expect(
      await read('$book/manuscript.md'),
      '![](gallery/foto%20da%20pista.png)\n',
    );

    // An old Markdown that points at the file gets the image by ID.
    await File(p.join(folder.path, book, 'manuscript.delta.json')).delete();
    final migrated = await repository.load(project);
    expect(RichDocument.galleryImageIds(migrated.book.singleDelta), {id});
  });

  test('referências a um elemento vêm das menções do texto', () async {
    await write('$book/manuscript.md', 'Oi [[element:lia|Lia]].\n');
    final loaded = await repository.load(project);
    final refs = loaded.book.referencesTo('lia', 'Manuscrito');
    expect(refs.single.chapterId, isNull);
    expect(refs.single.title, 'Manuscrito');
    expect(loaded.book.referencesTo('outro', 'Manuscrito'), isEmpty);
  });
}
