import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_type_editor.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

void main() {
  group('editor de tipos', () {
    Future<void> open(
      WidgetTester tester,
      void Function(ElementTypeEdit?) onResult, {
      ElementType? current,
      int usedBy = 0,
    }) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showElementTypeEditor(
                  context,
                  current: current,
                  usedBy: usedBy,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('cria um tipo com nome, detalhe e opções', (tester) async {
      ElementTypeEdit? result;
      await open(tester, (r) => result = r);
      await tester.enterText(find.byType(TextField).first, '  Magia ');
      await tester.tap(find.text('elements.add_field'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, '').last, 'Nível');
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();

      final saved = (result! as ElementTypeSaved).type;
      expect(saved.name, 'Magia');
      expect(saved.builtin, isFalse);
      expect(saved.fields.single.label, 'Nível');
      expect(saved.fields.single.kind, ElementFieldKind.text);
      expect(saved.id, startsWith('t_'));
    });

    testWidgets('não salva sem nome', (tester) async {
      ElementTypeEdit? result;
      await open(tester, (r) => result = r);
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('elements.title_required'), findsOneWidget);
    });

    testWidgets('campos sem nome são descartados ao salvar', (tester) async {
      ElementTypeEdit? result;
      await open(tester, (r) => result = r);
      await tester.enterText(find.byType(TextField).first, 'Magia');
      await tester.tap(find.text('elements.add_field'));
      await tester.pump();
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();
      expect((result! as ElementTypeSaved).type.fields, isEmpty);
    });

    testWidgets('editar mantém o ID e permite excluir quando não está em uso', (
      tester,
    ) async {
      const current = ElementType(
        id: 't_x',
        name: 'Magia',
        icon: IconRef('Feather', 'zap'),
        colorValue: 0xFF112233,
      );
      ElementTypeEdit? result;
      await open(tester, (r) => result = r, current: current);
      await tester.tap(find.text('elements.delete_type'));
      await tester.pumpAndSettle();
      expect((result! as ElementTypeDeleted).typeId, 't_x');
    });

    testWidgets('um tipo em uso não pode ser excluído', (tester) async {
      const current = ElementType(
        id: 't_x',
        name: 'Magia',
        icon: IconRef('Feather', 'zap'),
        colorValue: 0xFF112233,
      );
      ElementTypeEdit? result;
      await open(tester, (r) => result = r, current: current, usedBy: 3);
      await tester.tap(find.text('elements.delete_type'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('store', () {
    late Directory folder;
    late StoryProject project;
    late ProjectWorkspaceStore store;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('plotcraft-types-store-');
      final now = DateTime.utc(2026);
      project = StoryProject(
        id: 'st1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder.path,
      );
      await File(p.join(folder.path, 'project.json'))
          .writeAsString('{"id":"st1"}');
      store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
      await store.load(project);
    });

    tearDown(() => folder.delete(recursive: true));

    const magia = ElementType(
      id: 't_magia',
      name: 'Magia',
      icon: IconRef('Feather', 'zap'),
      colorValue: 0xFF7B5EA7,
    );

    test('salva, atualiza e remove tipos personalizados', () async {
      await store.saveElementType(magia);
      expect(store.elementTypes.map((t) => t.id), contains('t_magia'));
      await store.saveElementType(magia.copyWith(name: 'Magia antiga'));
      expect(store.customElementTypes.single.name, 'Magia antiga');

      final reloaded = ProjectWorkspaceStore(
        ProjectWorkspaceRepository(),
        (_) {},
      );
      await reloaded.load(store.project!);
      expect(reloaded.customElementTypes.single.name, 'Magia antiga');

      await store.removeElementType('t_magia');
      expect(store.customElementTypes, isEmpty);
    });

    test('não remove um tipo que algum elemento usa', () async {
      await store.saveElementType(magia);
      final now = DateTime.utc(2026);
      await store.saveElement(
        NarrativeElement(
          id: 'feitico',
          typeId: 't_magia',
          title: 'Fogo',
          summary: '',
          sections: const [],
          phases: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await expectLater(store.removeElementType('t_magia'), throwsStateError);
      expect(store.customElementTypes, hasLength(1));
    });
  });
}
