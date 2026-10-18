import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_tab_bar.dart';
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_editor.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/chapter_list.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/workspace_shell.dart';
import 'package:plotcraft/features/project_workspace/presentation/workspace_actions.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late StoryProject project;
  late WorkspaceController controller;
  late WorkspaceActions actions;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-shell-');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 's1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"s1"}');
    final manuscript = File(
      p.join(folder.path, 'content', 'book', 'manuscript.md'),
    );
    await manuscript.parent.create(recursive: true);
    await manuscript.writeAsString('Texto inicial.');
    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    controller = WorkspaceController(store, project, null);
    actions = WorkspaceActions(controller);
  });

  tearDown(() async {
    controller.dispose();
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(controller.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: WorkspaceShell(
          project: project,
          controller: controller,
          actions: actions,
          onBack: () {},
        ),
      ),
    );
    await tester.pump();
  }

  List<String> tabTitles(WidgetTester tester) => tester
      .widget<PlotcraftTabBar>(find.byType(PlotcraftTabBar))
      .tabs
      .map((tab) => tab.title)
      .toList();

  testWidgets(
    'abre o manuscrito em uma aba, marca como sujo e salva ao fechar',
    (tester) async {
      await pumpShell(tester);
      expect(tabTitles(tester), ['workspace.overview']);

      await tester.tap(find.byTooltip('workspace.manuscript'));
      await tester.pump();
      expect(find.byType(ChapterList), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(ChapterList),
          matching: find.text('workspace.manuscript'),
        ),
      );
      await tester.pump();
      expect(find.byType(BookEditor), findsOneWidget);
      expect(tabTitles(tester), ['workspace.overview', 'workspace.manuscript']);

      await tester.enterText(
        find.descendant(
          of: find.byType(BookEditor),
          matching: find.byType(TextField),
        ),
        'Texto editado.',
      );
      await tester.pump();
      expect(controller.isDirty('manuscript'), isTrue);

      await tester.runAsync(
        () => actions.closeTab(
          tester.element(find.byType(WorkspaceShell)),
          'manuscript',
        ),
      );
      await tester.pump();
      expect(find.byType(BookEditor), findsNothing);
      expect(tabTitles(tester), ['workspace.overview']);
      // Real file IO only completes outside the widget test's fake clock.
      final saved = await tester.runAsync(
        () =>
            File(p.join(folder.path, 'content', 'book', 'manuscript.md'))
                .readAsString(),
      );
      expect(saved, 'Texto editado.');
      // Let the spell check debounce and autosave timers elapse.
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('novo elemento abre um rascunho em aba própria', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byTooltip('elements.title'));
    await tester.pump();
    await tester.tap(find.byTooltip('elements.new'));
    await tester.pumpAndSettle();
    expect(find.text('elements.choose_type'), findsOneWidget);
    await tester.tap(find.text('elements.types.place'));
    await tester.pumpAndSettle();
    expect(find.byType(ElementEditor), findsOneWidget);
    expect(tabTitles(tester).last, 'elements.new');
    expect(controller.draftTypeFor(controller.activeTabId!), 'place');
  });

  testWidgets('alternar o inspetor e arrastar o divisor altera a largura', (
    tester,
  ) async {
    await pumpShell(tester);
    final initial = controller.inspectorWidth;
    expect(find.text('workspace.inspector'), findsOneWidget);

    controller.resizeInspector(-40);
    await tester.pump();
    expect(controller.inspectorWidth, initial + 40);

    controller.toggleInspector();
    await tester.pump();
    expect(find.text('workspace.inspector'), findsNothing);
  });
}
