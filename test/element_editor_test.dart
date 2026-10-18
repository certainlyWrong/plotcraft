import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_chip_input.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_editor.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_section_card.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_summary_panel.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'support/fake_fonts.dart';

void main() {
  late Directory folder;
  late StoryProject project;
  late ProjectWorkspaceStore store;
  late WorkspaceController controller;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-editor-');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 'ed1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"ed1"}');
    store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    controller = WorkspaceController(store, project, null, testFontsStore());
    await store.load(project);
  });

  tearDown(() async {
    controller.dispose();
    await folder.delete(recursive: true);
  });

  Future<void> pumpEditor(
    WidgetTester tester,
    WorkspaceTab tab, {
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: Scaffold(
          body: ElementEditor(
            tab: tab,
            store: store,
            controller: controller,
            book: store.book,
            onRemove: (_) {},
            onOpenReference: (_, _) {},
            onOpenElement: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'chips: Enter e vírgula adicionam, repetidos e vazios são ignorados',
    (tester) async {
      var values = <String>['Mari'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PlotcraftChipInput(
                values: values,
                onChanged: (next) => setState(() => values = next),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'A Corredora');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, ['Mari', 'A Corredora']);

      await tester.enterText(find.byType(TextField), 'mari');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, ['Mari', 'A Corredora']);

      await tester.enterText(find.byType(TextField), 'Lia,Ana,');
      await tester.pump();
      expect(values, ['Mari', 'A Corredora', 'Lia', 'Ana']);

      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pump();
      expect(values, ['A Corredora', 'Lia', 'Ana']);
    },
  );

  testWidgets(
    'largura grande: resumo ao lado; estreita: resumo compacto no topo',
    (tester) async {
      await pumpEditor(
        tester,
        WorkspaceTab.element('${WorkspaceTab.draftPrefix}1'),
        width: 1300,
      );
      final wide = tester.widget<ElementSummaryPanel>(
        find.byType(ElementSummaryPanel),
      );
      expect(wide.compact, isFalse);
      final summaryLeft = tester
          .getTopLeft(find.byType(ElementSummaryPanel))
          .dx;
      final formLeft = tester
          .getTopLeft(find.byType(ElementSectionCard).first)
          .dx;
      expect(summaryLeft, greaterThan(formLeft));

      await pumpEditor(
        tester,
        WorkspaceTab.element('${WorkspaceTab.draftPrefix}2'),
        width: 760,
      );
      final narrow = tester.widget<ElementSummaryPanel>(
        find.byType(ElementSummaryPanel),
      );
      expect(narrow.compact, isTrue);
      expect(
        tester.getTopLeft(find.byType(ElementSummaryPanel)).dy,
        lessThan(tester.getTopLeft(find.byType(ElementSectionCard).first).dy),
      );
    },
  );

  testWidgets(
    'um personagem novo salva apelidos, etiquetas e detalhes do tipo',
    (tester) async {
      final tabId = controller.newElementDraft('character');
      final tab = controller.tabs.firstWhere((t) => t.id == tabId);
      await pumpEditor(tester, tab);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Maria');
      await tester.enterText(fields.at(1), 'Mari, A Corredora,');
      await tester.enterText(fields.at(2), 'protagonista,');
      // The character type offers "Age" among its details.
      await tester.enterText(
        find.widgetWithText(TextField, 'elements.fields.age'),
        '17',
      );
      await tester.pump();
      expect(controller.isDirty(tabId), isTrue);

      // Tap inside runAsync so the save's file IO runs in the real zone.
      await tester.runAsync(() async {
        await tester.tap(find.text('workspace.save_project'));
        for (var i = 0; i < 200 && store.elements.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();

      expect(store.elements, hasLength(1));
      final saved = store.elements.single;
      expect(saved.title, 'Maria');
      expect(saved.typeId, 'character');
      expect(saved.aliases, ['Mari', 'A Corredora']);
      expect(saved.tags, ['protagonista']);
      expect(saved.fields['age'], '17');

      final file = File(
        p.join(
          folder.path,
          'content',
          'narrative',
          'elements',
          '${saved.id}.json',
        ),
      );
      final json = jsonDecode(
        await tester.runAsync(file.readAsString) as String,
      ) as Map<String, dynamic>;
      expect(json['schemaVersion'], 2);
      expect(json['aliases'], ['Mari', 'A Corredora']);
      expect((json['fields'] as Map)['age'], '17');
      // The draft tab was replaced by the saved element's tab.
      expect(controller.tabs.any((t) => t.id == 'element:${saved.id}'), isTrue);
    },
  );

  testWidgets('trocar o tipo troca os detalhes oferecidos', (tester) async {
    final tabId = controller.newElementDraft('character');
    await pumpEditor(tester, controller.tabs.firstWhere((t) => t.id == tabId));
    expect(find.text('elements.fields.age'), findsWidgets);
    expect(find.text('elements.fields.region'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('elements.types.place').last);
    await tester.pumpAndSettle();
    expect(find.text('elements.fields.region'), findsWidgets);
    expect(find.text('elements.fields.age'), findsNothing);
  });

  testWidgets(
    'desligar a marcação automática é salvo na política do elemento',
    (tester) async {
      final tabId = controller.newElementDraft('character');
      await pumpEditor(
        tester,
        controller.tabs.firstWhere((t) => t.id == tabId),
      );
      await tester.enterText(find.byType(TextField).first, 'Lia');
      final toggle = find.widgetWithText(
        SwitchListTile,
        'elements.auto_mentions',
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('workspace.save_project').first);
        for (var i = 0; i < 200 && store.elements.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      expect(store.elements.single.mentionPolicy.auto, isFalse);
    },
  );
}
