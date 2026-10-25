// Renders the screenshots shown in the README (English interface) from the
// bundled sample story ("Herdeiros do Silêncio") and saves them in
// docs/screenshots/.
//
//   tool/screenshots/readme.sh
//
// Not part of the regular test suite (it lives outside test/).
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/fonts/project_font_loader.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/app/app_commands.dart';
import 'package:plotcraft/core/storage/local_storage.dart';
import 'package:plotcraft/features/preferences/stores/theme_store.dart';
import 'package:plotcraft/features/project_creation/stores/project_creation_store.dart';
import 'package:plotcraft/features/projects/data/project_repository.dart';
import 'package:plotcraft/features/projects/data/sample_project_installer.dart';
import 'package:plotcraft/features/projects/presentation/project_home_screen.dart';
import 'package:plotcraft/features/projects/stores/project_store.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/workspace_shell.dart';
import 'package:plotcraft/features/project_workspace/presentation/workspace_actions.dart';
import 'package:plotcraft/features/project_workspace/stores/editor_fonts_store.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_files.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'harness.dart';

class _NoSystemFonts implements SystemFontLister {
  const _NoSystemFonts();

  @override
  Future<List<String>> families() async => const [];
}

final _out = Directory('docs/screenshots');
const _size = screenSize;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
    await initLocalization();
  });

  Future<WorkspaceController> open(
    WidgetTester tester, {
    String theme = 'gris-night',
  }) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('plotcraft-readme-'),
    ) as Directory;
    addTearDown(() => root.deleteSync(recursive: true));
    late StoryProject project;
    await tester.runAsync(() async {
      final folder = await SampleProjectInstaller().install(root.path);
      project = (await const ProjectLibrary().discover(knownFolders: [folder]))
          .single;
    });
    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    final controller = WorkspaceController(
      store,
      project,
      null,
      EditorFontsStore(
        const ProjectFontsRepository(ProjectFiles()),
        const ProjectFontLoader(),
        const _NoSystemFonts(),
      ),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.load);
    await pumpApp(
      tester,
      WorkspaceShell(
        project: project,
        controller: controller,
        actions: WorkspaceActions(controller),
        onBack: () {},
      ),
      theme: builtInThemes.firstWhere((t) => t.id == theme),
      locale: const Locale('en'),
      size: _size,
    );
    // The inspector would show a temporary folder path.
    if (controller.inspectorVisible) controller.toggleInspector();
    await settle(tester);
    return controller;
  }

  testWidgets('readme: mapa da história', (tester) async {
    final controller = await open(tester);
    controller.selectSection(WorkspaceSection.graph);
    await settle(tester, rounds: 30);
    await shot(tester, 'mapa-da-historia', directory: _out);
  });

  testWidgets('readme: modo leitura', (tester) async {
    final controller = await open(tester);
    controller.openReading(controller.store.book.chapters.first.id);
    await settle(tester, rounds: 10);
    await shot(tester, 'modo-leitura', directory: _out);
  });

  testWidgets('readme: personagem', (tester) async {
    final controller = await open(tester);
    controller.selectSection(WorkspaceSection.elements);
    controller.openTab(WorkspaceTab.element('inara'));
    await settle(tester, rounds: 12);
    await shot(tester, 'personagem', directory: _out);
  });

  testWidgets('readme: linha do tempo', (tester) async {
    final controller = await open(tester);
    controller.selectSection(WorkspaceSection.timeline);
    await settle(tester, rounds: 12);
    await shot(tester, 'linha-do-tempo', directory: _out);
  });

  testWidgets('readme: galeria', (tester) async {
    final controller = await open(tester);
    controller.selectSection(WorkspaceSection.gallery);
    await settle(tester, rounds: 25);
    await shot(tester, 'galeria', directory: _out);
  });

  testWidgets('readme: editor', (tester) async {
    final controller = await open(tester);
    controller.selectSection(WorkspaceSection.manuscript);
    controller.openManuscript(controller.store.book.chapters[6].id);
    await settle(tester, rounds: 12);
    await shot(tester, 'editor', directory: _out);
  });

  testWidgets('readme: tema claro', (tester) async {
    final controller = await open(tester, theme: 'gris-day');
    controller.openReading(controller.store.book.chapters[3].id);
    await settle(tester, rounds: 10);
    await shot(tester, 'tema-claro', directory: _out);
  });

  testWidgets('readme: biblioteca', (tester) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('plotcraft-readme-'),
    ) as Directory;
    addTearDown(() => root.deleteSync(recursive: true));
    late StoryProject project;
    await tester.runAsync(() async {
      final folder = await SampleProjectInstaller().install(root.path);
      project = (await const ProjectLibrary().discover(knownFolders: [folder]))
          .single;
    });
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = ProjectStore(
      ProjectRepository(storage, ProjectCreationService()),
    );
    store.projects.add(project);
    store.projectsRoot = root.path;
    store.isLoaded = true;
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
        commands: AppCommands(),
      ),
      theme: builtInThemes.firstWhere((t) => t.id == 'gris-night'),
      locale: const Locale('en'),
      size: _size,
    );
    await shot(tester, 'biblioteca', directory: _out);
  });
}
