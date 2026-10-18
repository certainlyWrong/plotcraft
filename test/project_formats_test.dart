import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/activity_bar.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/projects/data/project_creation_service.dart';
import 'package:plotcraft/features/projects/domain/project_format.dart';
import 'package:plotcraft/features/projects/domain/project_metadata_input.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

ProjectMetadataInput _input(String format, {String title = 'Meu projeto'}) =>
    ProjectMetadataInput(
      title: title,
      subtitle: '',
      author: '',
      description: '',
      genre: '',
      tags: const [],
      coverIndex: 0,
      primaryFormat: format,
    );

StoryProject _project(String id, String format) => StoryProject(
  id: id,
  title: 'T $id',
  description: '',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  coverIndex: 0,
  primaryFormat: format,
);

void main() {
  group('registro de formatos', () {
    test('livro tem manuscrito e mangá não', () {
      expect(ProjectFormats.book.hasManuscript, isTrue);
      expect(ProjectFormats.manga.hasManuscript, isFalse);
      expect(ProjectFormats.all.map((f) => f.id), ['book', 'manga']);
      expect(ProjectFormats.book.nameKey, 'formats.book.name');
    });

    test('formato desconhecido abre como livro', () {
      expect(ProjectFormats.of('audiobook'), ProjectFormats.book);
      expect(ProjectFormats.isKnown('audiobook'), isFalse);
      expect(ProjectFormats.isKnown('manga'), isTrue);
    });

    test('os ícones dos formatos existem no catálogo', () {
      for (final format in ProjectFormats.all) {
        expect(format.icon.exists, isTrue, reason: format.id);
      }
    });

    test('a entrada recusa um formato desconhecido', () {
      expect(() => _input('book').validate(), returnsNormally);
      expect(() => _input('manga').validate(), returnsNormally);
      expect(() => _input('audiobook').validate(), throwsFormatException);
    });

    test('o formato é salvo e lido no manifesto, com livro como padrão', () {
      final round = StoryProject.fromJson(_project('a', 'manga').toJson());
      expect(round.primaryFormat, 'manga');
      final old = StoryProject.fromJson(
        Map.of(_project('b', 'book').toJson())..remove('primaryFormat'),
      );
      expect(old.primaryFormat, 'book');
    });
  });

  group('criação em disco', () {
    late Directory root;
    final service = ProjectCreationService();

    setUp(
      () async =>
          root = await Directory.systemTemp.createTemp('plotcraft-fmt-'),
    );
    tearDown(() => root.delete(recursive: true));

    test(
      'um livro nasce com o manuscrito em Delta e a cópia em Markdown',
      () async {
        final project = await service.create(
          _input('book', title: 'Cidades de Sal'),
          root.path,
        );
        expect(project.primaryFormat, 'book');
        final book = p.join(project.directoryPath!, 'content', 'book');
        final delta = jsonDecode(
          await File(p.join(book, 'manuscript.delta.json')).readAsString(),
        ) as Map;
        expect((delta['ops'] as List).first, {'insert': 'Cidades de Sal'});
        expect(
          await File(p.join(book, 'manuscript.md')).readAsString(),
          '# Cidades de Sal\n',
        );
        // Nothing to convert on the first open, so no backup is made.
        final data = await ProjectWorkspaceRepository().load(project);
        expect(
          RichDocument.plainText(data.book.singleDelta),
          'Cidades de Sal\n\n',
        );
        expect(
          await Directory(p.join(book, 'migration-backup')).exists(),
          isFalse,
        );
      },
    );

    test('um mangá nasce sem a pasta do livro e abre sem erro', () async {
      final project = await service.create(_input('manga'), root.path);
      expect(project.primaryFormat, 'manga');
      expect(
        await Directory(p.join(project.directoryPath!, 'content', 'book'))
            .exists(),
        isFalse,
      );
      expect(
        await Directory(
          p.join(project.directoryPath!, 'content', 'narrative', 'elements'),
        ).exists(),
        isTrue,
      );
      final manifest = jsonDecode(
        await File(p.join(project.directoryPath!, 'project.json'))
            .readAsString(),
      ) as Map;
      expect(manifest['primaryFormat'], 'manga');
      final data = await ProjectWorkspaceRepository().load(project);
      expect(data.book.chapters, isEmpty);
      expect(data.book.wordCount, 0);
    });
  });

  group('barra de atividades', () {
    testWidgets('o mangá não mostra o manuscrito', (tester) async {
      Future<void> pump(List<WorkspaceSection> sections) => tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: Row(
              children: [
                ActivityBar(
                  selected: WorkspaceSection.overview,
                  sections: sections,
                  onSelect: (_) {},
                  onBack: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await pump(WorkspaceSection.values);
      expect(find.byTooltip('workspace.manuscript'), findsOneWidget);
      await pump([
        WorkspaceSection.overview,
        WorkspaceSection.elements,
        WorkspaceSection.gallery,
      ]);
      expect(find.byTooltip('workspace.manuscript'), findsNothing);
      expect(find.byTooltip('elements.title'), findsOneWidget);
    });
  });
}
