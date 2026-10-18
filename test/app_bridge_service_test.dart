import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/app/app_commands.dart';
import 'package:plotcraft/core/storage/local_storage.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/features/app_bridge/app_bridge_service.dart';
import 'package:plotcraft/features/preferences/stores/theme_store.dart';
import 'package:plotcraft/features/projects/data/project_repository.dart';
import 'package:plotcraft/features/projects/stores/project_store.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/app_bridge/bridge_protocol.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_fonts.dart';

class _FakeSpell implements SpellCheckBackend {
  final learned = <String>[];

  @override
  Future<List<Misspelling>> check(String text, Locale locale) async => [
    for (final match in RegExp('errro').allMatches(text))
      Misspelling(match.start, match.end),
  ];

  @override
  Future<List<String>> suggest(String word, Locale locale) async => ['erro'];

  @override
  Future<void> learn(String word) async => learned.add(word);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProjectStore projects;
  late ThemeStore themes;
  late AppCommands commands;
  late _FakeSpell spell;
  late AppBridgeService service;
  late Locale? changedTo;

  Future<Object?> call(
    String method, [
    Map<String, Object?> params = const {},
  ]) => service.handlers[method]!(params);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    root = await Directory.systemTemp.createTemp('plotcraft-service-');
    await storage.saveProjectsRoot(root.path);
    projects = ProjectStore(
      ProjectRepository(storage, ProjectCreationService()),
    );
    projects.projectsRoot = root.path;
    themes = ThemeStore(storage);
    commands = AppCommands();
    spell = _FakeSpell();
    changedTo = null;
    commands.setLocale = (locale) async => changedTo = locale;
    service = AppBridgeService(
      projects: projects,
      themes: themes,
      commands: commands,
      languages: const ['en', 'pt'],
      currentLanguage: () => 'pt',
      spell: spell,
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('preferências e temas', () async {
    final prefs = await call('get_preferences') as Map;
    expect(prefs['theme'], 'violet');
    expect(prefs['languages'], ['en', 'pt']);
    expect(prefs['projects_folder'], root.path);
    final listed = await call('list_themes') as Map;
    expect((listed['themes'] as List).first, containsPair('id', 'violet'));
  });

  test('trocar tema, fonte e idioma, e recusar valores inválidos', () async {
    await call('set_theme', {'theme_id': 'paper'});
    expect(themes.selectedThemeId, 'paper');
    await expectLater(
      call('set_theme', {'theme_id': 'nao-existe'}),
      throwsA(
        isA<BridgeError>().having((e) => e.code, 'code', 'invalid_params'),
      ),
    );
    await call('set_interface_font', {'family': 'Lora'});
    expect(themes.fontFamily, 'Lora');
    await expectLater(
      call('set_interface_font', {'family': 'Comic Sans'}),
      throwsA(isA<BridgeError>()),
    );
    await call('set_language', {'language': 'en'});
    expect(changedTo, const Locale('en'));
    await expectLater(
      call('set_language', {'language': 'xx'}),
      throwsA(isA<BridgeError>()),
    );
    await expectLater(call('set_theme', {}), throwsA(isA<BridgeError>()));
  });

  test('no macOS a pasta de projetos só muda pelo seletor do app', () async {
    if (!Platform.isMacOS) return;
    await expectLater(
      call('set_projects_root', {'path': '/tmp'}),
      throwsA(isA<BridgeError>().having((e) => e.code, 'code', 'unsupported')),
    );
  });

  test('corretor: verifica, sugere e aprende', () async {
    if (!MethodChannelSpellCheckBackend.isSupported) return;
    final checked = await call('spell_check', {'text': 'um errro aqui'}) as Map;
    final first = (checked['misspellings'] as List).single as Map;
    expect(first['word'], 'errro');
    expect(first['suggestions'], ['erro']);
    expect(
      ((await call('spell_suggest', {'word': 'errro'})) as Map)['suggestions'],
      ['erro'],
    );
    await call('spell_learn', {'word': 'Lia'});
    expect(spell.learned, ['Lia']);
  });

  test('abrir no app: projeto, capítulo com trecho e elemento', () async {
    final project = await ProjectCreationService().create(
      const ProjectMetadataInput(
        title: 'Para abrir',
        subtitle: '',
        author: '',
        description: '',
        genre: '',
        tags: [],
        coverIndex: 0,
      ),
      root.path,
    );
    projects.addCreated(project);
    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    final controller = WorkspaceController(
      store,
      project,
      null,
      testFontsStore(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    commands.workspaceOpened(project.id, controller);
    final chapter = store.book.chapters.first.id;

    await expectLater(
      call('open_in_app', {'project_id': 'desconhecido'}),
      throwsA(isA<BridgeError>()),
    );
    final opened = await call('open_in_app', {
      'project_id': project.id,
      'chapter_id': chapter,
      'start': 2,
      'end': 5,
    }) as Map;
    expect(opened['opened'], isTrue);
    expect(controller.activeTabId, 'chapter:$chapter');
    expect(
      controller.revealRequests['chapter:$chapter'],
      const TextRange(start: 2, end: 5),
    );
    await expectLater(
      call('open_in_app', {'project_id': project.id, 'chapter_id': 'x'}),
      throwsA(isA<BridgeError>()),
    );
    await expectLater(
      call('open_in_app', {'project_id': project.id, 'element_id': 'x'}),
      throwsA(isA<BridgeError>()),
    );
    expect(p.isAbsolute(root.path), isTrue);
  });

  test('não troca de projeto se o aberto tem alterações não salvas', () async {
    final first = await ProjectCreationService().create(
      const ProjectMetadataInput(
        title: 'Primeiro',
        subtitle: '',
        author: '',
        description: '',
        genre: '',
        tags: [],
        coverIndex: 0,
      ),
      root.path,
    );
    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    final controller = WorkspaceController(
      store,
      first,
      null,
      testFontsStore(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    commands.workspaceOpened(first.id, controller);
    controller.setDirty('chapter:x', true);
    await expectLater(
      commands.openProject('outro', timeout: const Duration(milliseconds: 200)),
      throwsA(isA<BridgeError>().having((e) => e.code, 'code', 'conflict')),
    );
  });
}
