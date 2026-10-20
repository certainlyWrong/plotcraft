import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/storage/local_storage.dart';
import 'package:plotcraft/features/projects/data/project_repository.dart';
import 'package:plotcraft/features/projects/data/sample_project_installer.dart';
import 'package:plotcraft/features/projects/stores/project_store.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plotcraft-sample-'));
  tearDown(() => root.deleteSync(recursive: true));

  test('copia o exemplo completo para a pasta de projetos', () async {
    final folder = await SampleProjectInstaller().install(root.path);
    expect(p.dirname(folder), root.path);
    expect(Directory('$folder.partial').existsSync(), isFalse);

    final projects = await const ProjectLibrary().discover(
      knownFolders: [folder],
      root: root.path,
    );
    expect(projects, hasLength(1));
    final project = projects.single;
    expect(project.title, 'Herdeiros do Silêncio');
    expect(project.tags, contains('demo'));
    expect(project.id, await SampleProjectInstaller().sampleId());

    final data = await ProjectWorkspaceRepository().load(project);
    expect(data.book.chapters, hasLength(12));
    expect(data.elements.length, greaterThan(30));
    expect(data.types.map((t) => t.name), contains('Voz'));
    expect(data.galleryItems, hasLength(30));
    // Every image in the gallery index and the cover are really there.
    expect(data.galleryItems.every((item) => item.exists), isTrue);
    expect(File(p.join(folder, project.coverFile!)).existsSync(), isTrue);
  });

  test('instalar de novo não copia nada nem mexe nas edições', () async {
    final installer = SampleProjectInstaller();
    final folder = await installer.install(root.path);
    final manifest = File(p.join(folder, 'project.json'));
    final edited = jsonEncode({
      ...jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>,
      'title': 'Meu título',
    });
    manifest.writeAsStringSync(edited);
    expect(await installer.install(root.path), folder);
    expect(manifest.readAsStringSync(), edited);
  });

  test('o repositório e a loja oferecem o exemplo uma vez', () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => root.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    await storage.saveProjectsRoot(root.path);
    final store = ProjectStore(
      ProjectRepository(storage, ProjectCreationService()),
    );
    await store.load();
    expect(store.canInstallSample, isTrue);

    final sample = await store.installSample();
    expect(sample.title, 'Herdeiros do Silêncio');
    expect(store.projects.map((project) => project.id), [sample.id]);
    expect(store.canInstallSample, isFalse);
  });
}
