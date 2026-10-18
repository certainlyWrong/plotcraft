// Renders the main screens and saves them as PNG files in build/screenshots/.
//
//   flutter test tool/screenshots/screens_test.dart
//   flutter test tool/screenshots/screens_test.dart --plain-name "workspace"
//
// Not part of the regular test suite (it lives outside test/).
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/fonts/project_font_loader.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';
import 'package:plotcraft/core/storage/local_storage.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/preferences/stores/theme_store.dart';
import 'package:plotcraft/features/project_creation/presentation/project_creation_screen.dart';
import 'package:plotcraft/features/project_creation/stores/project_creation_store.dart';
import 'package:plotcraft/features/project_workspace/data/project_files.dart';
import 'package:plotcraft/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/workspace_shell.dart';
import 'package:plotcraft/features/project_workspace/presentation/workspace_actions.dart';
import 'package:plotcraft/features/project_workspace/stores/editor_fonts_store.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft/features/projects/data/project_creation_service.dart';
import 'package:plotcraft/features/projects/data/project_repository.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';
import 'package:plotcraft/features/projects/presentation/project_home_screen.dart';
import 'package:plotcraft/features/projects/stores/project_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';
import 'sample_project.dart';

class _SomeFonts implements SystemFontLister {
  const _SomeFonts();

  @override
  Future<List<String>> families() async => [
    'Arial',
    'Baskerville',
    'Georgia',
    'Helvetica Neue',
    'Palatino',
    'Times New Roman',
  ];
}

void main() {
  late Directory root;
  late StoryProject book;
  late StoryProject manga;
  late StoryProject empty;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
    await initLocalization();
  });

  Future<void> prepare(WidgetTester tester) async {
    root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('plotcraft-shots-'),
    ) as Directory;
    addTearDown(() => root.deleteSync(recursive: true));
    await tester.runAsync(() async {
      book = await buildSampleBook(root);
      manga = await buildSampleManga(root);
      empty = await buildEmptyBook(root);
    });
  }

  Future<WorkspaceController> openWorkspace(
    WidgetTester tester,
    StoryProject project, {
    ThemeDefinition? theme,
    Size size = screenSize,
  }) async {
    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    final controller = WorkspaceController(
      store,
      project,
      null,
      EditorFontsStore(
        const ProjectFontsRepository(ProjectFiles()),
        const ProjectFontLoader(),
        const _SomeFonts(),
      ),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.load);
    final actions = WorkspaceActions(controller);
    await pumpApp(
      tester,
      WorkspaceShell(
        project: project,
        controller: controller,
        actions: actions,
        onBack: () {},
      ),
      theme: theme,
      size: size,
    );
    return controller;
  }

  Future<void> tapTip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip).first);
    await settle(tester);
  }

  testWidgets('workspace: visão geral', (tester) async {
    await prepare(tester);
    await openWorkspace(tester, book);
    await shot(tester, '01-workspace-visao-geral');
  });

  testWidgets('workspace: manuscrito', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(tester, book);
    controller.selectSection(WorkspaceSection.manuscript);
    controller.openManuscript(
      book.directoryPath == null
          ? null
          : controller.store.book.chapters.first.id,
    );
    await settle(tester, rounds: 10);
    await shot(tester, '02-workspace-manuscrito');
    await tapTip(tester, 'Ligar a um elemento (@)');
    await shot(tester, '03-seletor-de-mencao');
  });

  testWidgets('workspace: elementos e editor de elemento', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(
      tester,
      book,
      size: const Size(1440, 2000),
    );
    controller.selectSection(WorkspaceSection.elements);
    controller.openTab(WorkspaceTab.element('maria'));
    await settle(tester, rounds: 8);
    await shot(tester, '04-elemento-maria');
  });

  testWidgets('workspace: escolha de tipo e editor de tipo', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(tester, book);
    controller.selectSection(WorkspaceSection.elements);
    controller.openTab(WorkspaceTab.element('pista'));
    await settle(tester, rounds: 6);
    await tapTip(tester, 'Novo elemento');
    await shot(tester, '05-escolha-de-tipo');
  });

  testWidgets('workspace: galeria', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(tester, book);
    controller.selectSection(WorkspaceSection.gallery);
    await settle(tester, rounds: 8);
    await shot(tester, '06-galeria');
  });

  testWidgets('workspace: configurações do projeto', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(
      tester,
      book,
      size: const Size(1440, 1500),
    );
    controller.openTab(WorkspaceTab.settings);
    await settle(tester, rounds: 6);
    await shot(tester, '07-configuracoes-do-projeto');
  });

  testWidgets('workspace: fontes do projeto', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(tester, book);
    controller.openManuscript(controller.store.book.chapters.first.id);
    await settle(tester, rounds: 8);
    await tapTip(tester, 'Fontes');
    await shot(tester, '08-fontes-do-projeto');
  });

  testWidgets('workspace: projeto em branco', (tester) async {
    await prepare(tester);
    await openWorkspace(tester, empty);
    await shot(tester, '09-projeto-em-branco');
  });

  testWidgets('workspace: mangá', (tester) async {
    await prepare(tester);
    await openWorkspace(tester, manga);
    await shot(tester, '10-manga');
  });

  testWidgets('workspace: tema escuro', (tester) async {
    await prepare(tester);
    final controller = await openWorkspace(
      tester,
      book,
      theme: builtInThemes.firstWhere((t) => t.id == 'midnight'),
    );
    controller.openManuscript(controller.store.book.chapters.first.id);
    await settle(tester, rounds: 8);
    await shot(tester, '11-tema-escuro-manuscrito');
  });

  Future<ProjectStore> libraryStores(
    WidgetTester tester,
    List<StoryProject> projects,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = ProjectCreationService();
    final repository = ProjectRepository(storage, service);
    final store = ProjectStore(repository);
    store.projects.addAll(projects);
    store.projectsRoot = root.path;
    store.isLoaded = true;
    return store;
  }

  testWidgets('biblioteca de projetos', (tester) async {
    await prepare(tester);
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = await libraryStores(tester, [book, manga, empty]);
    final themes = ThemeStore(storage);
    await tester.runAsync(themes.load);
    final creation = ProjectCreationStore(
      ProjectRepository(storage, ProjectCreationService()),
      ProjectCreationService(),
      store.addCreated,
    );
    await pumpApp(
      tester,
      ProjectHomeScreen(
        projects: store,
        creation: creation,
        themes: themes,
        storage: storage,
      ),
    );
    await shot(tester, '12-biblioteca');
    await tapTip(tester, 'Preferências');
    await shot(tester, '14-preferencias');
  });

  testWidgets('criação de projeto', (tester) async {
    await prepare(tester);
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = await libraryStores(tester, [book]);
    final creation = ProjectCreationStore(
      ProjectRepository(storage, ProjectCreationService()),
      ProjectCreationService(),
      store.addCreated,
    );
    await pumpApp(
      tester,
      Scaffold(
        body: ProjectCreationScreen(
          onCancel: () {},
          onCreated: (_) {},
          store: creation,
          destinationPath: root.path,
        ),
      ),
      size: const Size(1440, 1300),
    );
    await shot(tester, '13-criar-projeto');
  });
}
