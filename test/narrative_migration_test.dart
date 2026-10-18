import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_migration.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';
import 'package:plotcraft/features/project_workspace/presentation/element_colors.dart';

NarrativeElement _element(String id, String typeId) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: 'T $id',
  summary: '',
  sections: const [],
  phases: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('lê o elemento real da versão 1 sem perder dados', () {
    final json = jsonDecode(
      File('test/fixtures/narrative_element_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['schemaVersion'], 1);
    final element = NarrativeElement.fromJson(json);
    expect(element.id, 'hnbble1fpk');
    expect(element.typeId, 'character');
    expect(element.title, 'AAAAA');
    expect(element.summary, 'sadfasfsdf');
    expect(element.aliases, isEmpty);
    expect(element.images, isEmpty);
    expect(element.mentionPolicy.auto, isTrue);
    expect(element.createdAt, DateTime.parse(json['createdAt'] as String));
  });

  test('o JSON da versão 2 faz ida e volta com todos os campos', () {
    final element = NarrativeElement(
      id: 'e1',
      typeId: 'character',
      title: 'Maria',
      aliases: const ['Mari', 'A Corredora'],
      summary: 'resumo',
      tags: const ['protagonista'],
      icon: const IconRef('Feather', 'zap'),
      colorValue: 0xFF112233,
      images: const [
        ElementImage.gallery('g1'),
        ElementImage.attachment('content/narrative/attachments/e1/a.png'),
      ],
      fields: const {'age': '17'},
      sections: const [NarrativeSection(id: 's', title: 'S', markdown: 'm')],
      phases: const [NarrativePhase(id: 'p', title: 'P', description: 'd')],
      mentionPolicy: const MentionPolicy(auto: false, ignoredTerms: ['Mari']),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
    );
    final json = element.toJson();
    expect(json['schemaVersion'], 2);
    expect(json.containsKey('kind'), isFalse);
    final read = NarrativeElement.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );
    expect(read.aliases, ['Mari', 'A Corredora']);
    expect(read.tags, ['protagonista']);
    expect(read.icon, const IconRef('Feather', 'zap'));
    expect(read.color, const Color(0xFF112233));
    expect(read.images, element.images);
    expect(read.fields, {'age': '17'});
    expect(read.sections.single.markdown, 'm');
    expect(read.mentionPolicy.auto, isFalse);
    expect(read.mentionPolicy.ignoredTerms, ['Mari']);
  });

  test('referências de imagem inválidas são descartadas', () {
    expect(ElementImage.fromJson({'ref': 'gallery', 'id': ''}), isNull);
    expect(ElementImage.fromJson({'ref': 'attachment'}), isNull);
    expect(ElementImage.fromJson({'ref': 'outra', 'id': 'x'}), isNull);
    expect(ElementImage.fromJson('texto'), isNull);
  });

  test('tipos livres antigos viram tipos personalizados únicos', () {
    final upgrade = upgradeLegacyKinds([
      _element('a', 'character'),
      _element('b', 'Monster'),
      _element('c', 'monster'),
      _element('d', 'Lugar Mágico'),
      _element('e', ''),
    ], const []);
    expect(upgrade.typesChanged, isTrue);
    expect(upgrade.elements[0].typeId, 'character');
    expect(upgrade.elements[1].typeId, upgrade.elements[2].typeId);
    final names = upgrade.types.map((type) => type.name).toList();
    expect(names, ['Monster', 'Lugar Mágico', 'note']);
    expect(upgrade.types.map((type) => type.id), [
      't_monster',
      't_lugar_mágico',
      't_note',
    ]);
    expect(upgrade.elements[4].typeId, 't_note');
  });

  test('tipos já conhecidos não geram mudanças', () {
    const custom = ElementType(
      id: 't_magia',
      name: 'Magia',
      icon: IconRef.fallback,
      colorValue: 0xFF000000,
    );
    final upgrade = upgradeLegacyKinds(
      [_element('a', 't_magia'), _element('b', 'place')],
      [custom],
    );
    expect(upgrade.typesChanged, isFalse);
    expect(upgrade.types, [custom]);
  });

  group('abertura de um projeto com elementos antigos', () {
    late Directory folder;
    late StoryProject project;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('plotcraft-migration-');
      final now = DateTime.utc(2026);
      project = StoryProject(
        id: 'm1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder.path,
      );
      await File(p.join(folder.path, 'project.json'))
          .writeAsString('{"id":"m1"}');
      final elements = Directory(
        p.join(folder.path, 'content', 'narrative', 'elements'),
      );
      await elements.create(recursive: true);
      await File('test/fixtures/narrative_element_v1.json')
          .copy(p.join(elements.path, 'hnbble1fpk.json'));
      await File(p.join(elements.path, 'old.json')).writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'id': 'old',
          'kind': 'Dragão',
          'title': 'Smaug',
          'summary': '',
          'sections': [],
          'phases': [],
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        }),
      );
    });

    tearDown(() => folder.delete(recursive: true));

    test('cria o tipo e não altera os arquivos dos elementos', () async {
      final before = await File(
        p.join(folder.path, 'content', 'narrative', 'elements', 'old.json'),
      ).readAsString();
      final data = await ProjectWorkspaceRepository().load(project);
      expect(data.elements.map((e) => e.typeId).toSet(), {
        'character',
        't_dragão',
      });
      expect(data.types.single.name, 'Dragão');
      // The element file keeps the old format until the element is edited.
      expect(
        await File(
          p.join(folder.path, 'content', 'narrative', 'elements', 'old.json'),
        ).readAsString(),
        before,
      );
      // The new type is saved, so a later save of the element stays valid.
      final saved = await ProjectWorkspaceRepository().types.load(folder.path);
      expect(saved.single.id, 't_dragão');
      final manifest = await File(p.join(folder.path, 'project.json'))
          .readAsString();
      expect(manifest, '{"id":"m1"}');
    });
  });
}
