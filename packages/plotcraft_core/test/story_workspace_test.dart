import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/delta_edit.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';
import 'package:test/test.dart';

Delta _text(String value) => Delta()..insert('$value\n');

NarrativeElement _element(
  String id,
  String title, {
  String typeId = 'character',
  List<ElementRelation> relations = const [],
}) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: title,
  summary: '',
  sections: const [],
  phases: const [],
  relations: relations,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late Directory root;
  late StoryWorkspace story;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plotcraft-story-');
    final project = await ProjectCreationService().create(
      const ProjectMetadataInput(
        title: 'A Corredora',
        subtitle: '',
        author: '',
        description: '',
        genre: '',
        tags: [],
        coverIndex: 0,
      ),
      root.path,
    );
    story = await StoryWorkspace.open(project);
  });

  tearDown(() => root.delete(recursive: true));

  Future<StoryError> failure(Future<Object?> Function() action) async {
    try {
      await action();
    } on StoryError catch (error) {
      return error;
    }
    fail('Expected a StoryError');
  }

  test('um projeto novo abre com o primeiro capítulo vazio', () async {
    final chapters = await story.chapters();
    expect(chapters, hasLength(1));
    expect(chapters.single.title, 'Chapter 1');
    expect(chapters.single.words, 0);
  });

  test(
    'escrever um capítulo devolve a revisão e recusa uma revisão velha',
    () async {
      final id = (await story.chapters()).single.id;
      final first = await story.readChapter(id);
      final revision = await story.writeChapter(
        id,
        _text('Um dois três'),
        baseRevision: first.revision,
      );
      expect(revision, isNot(first.revision));
      expect((await story.chapters()).single.words, 3);

      final error = await failure(
        () => story.writeChapter(
          id,
          _text('Outro'),
          baseRevision: first.revision,
        ),
      );
      expect(error.code, StoryErrorCode.conflict);
      expect(
        DeltaEdit.text((await story.readChapter(id)).delta),
        'Um dois três\n',
      );

      await story.writeChapter(id, _text('Outro'), baseRevision: revision);
      expect(DeltaEdit.text((await story.readChapter(id)).delta), 'Outro\n');
    },
  );

  test('adicionar, renomear, reordenar e remover capítulos', () async {
    final first = (await story.chapters()).single.id;
    final second = await story.addChapter('Segundo', content: _text('Texto 2'));
    final zero = await story.addChapter('Zero', position: 0);
    expect((await story.chapters()).map((c) => c.title), [
      'Zero',
      'Chapter 1',
      'Segundo',
    ]);

    await story.renameChapter(second, 'Segundo capítulo');
    await story.reorderChapters([second, zero, first]);
    expect((await story.chapters()).map((c) => c.title), [
      'Segundo capítulo',
      'Zero',
      'Chapter 1',
    ]);
    expect(
      (await failure(() => story.reorderChapters([first]))).code,
      StoryErrorCode.validation,
    );

    await story.removeChapter(zero);
    expect((await story.chapters()), hasLength(2));
    await story.removeChapter(second);
    expect(
      (await failure(() => story.removeChapter(first))).code,
      StoryErrorCode.validation,
    );
    expect(
      (await failure(() => story.readChapter('nao-existe'))).code,
      StoryErrorCode.notFound,
    );
  });

  test('buscar e substituir no manuscrito, com simulação por padrão', () async {
    final a = (await story.chapters()).single.id;
    final b = await story.addChapter(
      'B',
      content: _text('o sal e o mar e o SAL'),
    );
    await story.writeChapter(a, _text('Sal na pista'));

    final found = await story.search('sal');
    expect(found.map((m) => m.chapterId).toSet(), {a, b});
    expect(found, hasLength(3));
    expect(found.first.snippet, contains('Sal'));

    final dry = await story.replaceInManuscript('sal', 'areia');
    expect(dry.fold<int>(0, (sum, o) => sum + o.count), 3);
    expect(
      DeltaEdit.text((await story.readChapter(a)).delta),
      'Sal na pista\n',
    );

    await story.replaceInManuscript('sal', 'areia', dryRun: false);
    expect(
      DeltaEdit.text((await story.readChapter(a)).delta),
      'areia na pista\n',
    );
    expect(
      DeltaEdit.text((await story.readChapter(b)).delta),
      contains('o areia e o mar e o areia'),
    );
    expect(
      (await failure(() => story.search('(', regex: true))).code,
      StoryErrorCode.validation,
    );
  });

  test('Markdown com menção e imagem da galeria vira Delta e volta', () async {
    final image = await story.importImageData(
      'pista.png',
      Uint8List.fromList([1, 2, 3]),
    );
    final delta = await story.fromMarkdown(
      'Ela viu [[element:lia|Lia]] correr.\n\n![](gallery://${image.id})\n\n---\n',
    );
    expect(RichDocument.mentionedIds(delta), ['lia']);
    expect(RichDocument.galleryImageIds(delta), {image.id});
    final markdown = await story.toMarkdown(delta);
    expect(markdown, contains('[[element:lia|Lia]]'));
    expect(markdown, contains('![](gallery/pista.png)'));
  });

  test(
    'elementos: criar, revisão, relação e remoção que limpa relações',
    () async {
      final maria = await story.saveElement(_element('maria', 'Maria'));
      final lia = await story.saveElement(
        _element(
          'lia',
          'Lia',
          relations: const [
            ElementRelation(id: 'r1', targetId: 'maria', label: 'amiga de'),
          ],
        ),
      );
      expect((await story.elements()).map((r) => r.element.id), [
        'lia',
        'maria',
      ]);

      final error = await failure(
        () => story.saveElement(
          maria.element.copyWith(summary: 'x'),
          baseRevision: 'velha',
        ),
      );
      expect(error.code, StoryErrorCode.conflict);
      await story.saveElement(
        maria.element.copyWith(summary: 'Corredora'),
        baseRevision: maria.revision,
      );

      expect(
        (await failure(
          () => story.saveElement(_element('x', 'X', typeId: 'zzz')),
        )).code,
        StoryErrorCode.validation,
      );
      expect(
        (await failure(
          () => story.saveElement(
            _element(
              'y',
              'Y',
              relations: const [ElementRelation(id: 'r', targetId: 'ninguem')],
            ),
          ),
        )).code,
        StoryErrorCode.notFound,
      );

      await story.removeElement('maria');
      final remaining = await story.element('lia');
      expect(remaining.element.relations, isEmpty);
      expect(
        Directory(p.join(story.folder, 'content', 'narrative', 'archive'))
            .existsSync(),
        isTrue,
      );
      expect(lia.element.relations, hasLength(1));
    },
  );

  test('tipos personalizados: salvar, usar e só remover sem uso', () async {
    const magia = ElementType(
      id: 't_magia',
      name: 'Magia',
      icon: const IconRef('Feather', 'star'),
      colorValue: 0xFF7B5EA7,
      fields: [],
    );
    await story.saveType(magia);
    expect((await story.types()).any((t) => t.id == 't_magia'), isTrue);
    await story.saveElement(_element('feitico', 'Feitiço', typeId: 't_magia'));
    expect(
      (await failure(() => story.removeType('t_magia'))).code,
      StoryErrorCode.validation,
    );
    await story.removeElement('feitico');
    await story.removeType('t_magia');
    expect((await story.types()).any((t) => t.id == 't_magia'), isFalse);
    expect(
      (await failure(
        () => story.saveType(
          const ElementType(
            id: 'character',
            name: 'x',
            icon: IconRef('Feather', 'star'),
            colorValue: 1,
            fields: [],
          ),
        ),
      )).code,
      StoryErrorCode.validation,
    );
  });

  test('galeria: importar bytes e remover', () async {
    final item = await story.importImageData(
      'capa.png',
      Uint8List.fromList([9, 9]),
    );
    expect(item.exists, isTrue);
    expect(await story.gallery(), hasLength(1));
    await story.removeGalleryImage(item.id);
    expect((await story.gallery()).where((i) => i.exists), isEmpty);
    expect(
      (await failure(() => story.removeGalleryImage('g_x'))).code,
      StoryErrorCode.notFound,
    );
  });

  test('visão geral e referências a um elemento', () async {
    final id = (await story.chapters()).single.id;
    await story.saveElement(_element('maria', 'Maria'));
    await story.writeChapter(id, _text('Maria correu. Maria parou.'));
    final overview = await story.overview();
    expect(overview['chapters'], 1);
    expect(overview['elements'], 1);
    expect((await story.referencesTo('maria')), hasLength(2));
  });
}
