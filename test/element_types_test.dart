import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/icons/icon_ref.dart';
import 'package:plotcraft/features/project_workspace/data/element_types_repository.dart';
import 'package:plotcraft/features/project_workspace/data/project_files.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  test('todo tipo pré-criado tem ícone existente, nome e campos únicos', () {
    final ids = <String>{};
    for (final type in ElementTypeCatalog.builtin) {
      expect(ids.add(type.id), isTrue, reason: 'ID repetido ${type.id}');
      expect(type.builtin, isTrue);
      expect(type.icon.exists, isTrue, reason: 'ícone de ${type.id}');
      expect(type.nameKey, 'elements.types.${type.id}');
      final fieldIds = type.fields.map((field) => field.id).toSet();
      expect(fieldIds.length, type.fields.length);
    }
    expect(ids, containsAll(['character', 'place', 'object', 'creature']));
  });

  test('resolve prefere o tipo pré-criado e aceita tipos personalizados', () {
    const custom = ElementType(
      id: 't_magia',
      name: 'Magia',
      icon: IconRef('Feather', 'zap'),
      color: Color(0xFF7B5EA7),
    );
    expect(ElementTypeCatalog.resolve('character', [custom])?.builtin, isTrue);
    expect(ElementTypeCatalog.resolve('t_magia', [custom]), custom);
    expect(ElementTypeCatalog.resolve('inexistente', [custom]), isNull);
  });

  test('tipo personalizado: JSON de ida e volta e entradas inválidas', () {
    const type = ElementType(
      id: 't1',
      name: 'Magia',
      icon: IconRef('RpgAwesome', 'crystal_ball'),
      color: Color(0xFF112233),
      fields: [
        ElementField(
          id: 'nivel',
          label: 'Nível',
          kind: ElementFieldKind.choice,
          options: ['I', 'II'],
        ),
      ],
    );
    final read = ElementType.fromJson(type.toJson())!;
    expect(read.name, 'Magia');
    expect(read.icon, type.icon);
    expect(read.color, type.color);
    expect(read.fields.single.kind, ElementFieldKind.choice);
    expect(read.fields.single.options, ['I', 'II']);

    expect(ElementType.fromJson({'id': 'x'}), isNull);
    expect(ElementType.fromJson({'id': 'x', 'name': '  '}), isNull);
    expect(ElementType.fromJson('texto'), isNull);
    final lenient = ElementType.fromJson({
      'id': 'x',
      'name': 'Y',
      'icon': 1,
      'color': 'zz',
    })!;
    expect(lenient.icon, IconRef.fallback);
  });

  group('repositório', () {
    late Directory folder;
    late StoryProject project;
    const repository = ElementTypesRepository(ProjectFiles());

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('plotcraft-types-');
      final now = DateTime.utc(2026);
      project = StoryProject(
        id: 'ty1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder.path,
      );
      await File(p.join(folder.path, 'project.json'))
          .writeAsString('{"id":"ty1"}');
    });

    tearDown(() => folder.delete(recursive: true));

    test('sem arquivo não há tipos personalizados', () async {
      expect(await repository.load(folder.path), isEmpty);
    });

    test('salva e relê só os tipos personalizados', () async {
      const custom = ElementType(
        id: 't1',
        name: 'Magia',
        icon: IconRef('Feather', 'zap'),
        color: Color(0xFF7B5EA7),
      );
      await repository.save(project, [...ElementTypeCatalog.builtin, custom]);
      final loaded = await repository.load(folder.path);
      expect(loaded.map((type) => type.id), ['t1']);
    });

    test('recusa nome vazio e IDs repetidos', () async {
      const empty = ElementType(
        id: 't1',
        name: ' ',
        icon: IconRef.fallback,
        color: Color(0xFF000000),
      );
      await expectLater(
        repository.save(project, [empty]),
        throwsFormatException,
      );
      final a = empty.copyWith(name: 'A');
      await expectLater(
        repository.save(project, [a, a]),
        throwsFormatException,
      );
    });

    test(
      'arquivo corrompido ou com ID de tipo pré-criado é tolerado',
      () async {
        final file = File(
          p.join(folder.path, 'content', 'narrative', 'types.json'),
        );
        await file.parent.create(recursive: true);
        await file.writeAsString('{ não é json');
        expect(await repository.load(folder.path), isEmpty);

        await file.writeAsString(
          '{"types":[{"id":"character","name":"X"},{"id":"ok","name":"Ok"},{"id":"ok","name":"Repetido"},{"nome":"sem id"}]}',
        );
        final loaded = await repository.load(folder.path);
        expect(loaded.map((type) => type.name), ['Ok']);
      },
    );
  });
}
