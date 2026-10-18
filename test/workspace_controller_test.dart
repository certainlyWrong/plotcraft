import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

void main() {
  late Directory folder;
  late StoryProject project;
  late ProjectWorkspaceStore store;
  late WorkspaceController controller;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plotcraft-workspace-');
    final now = DateTime.utc(2026);
    project = StoryProject(
      id: 'w1',
      title: 'Livro',
      description: '',
      createdAt: now,
      updatedAt: now,
      coverIndex: 0,
      directoryPath: folder.path,
    );
    await File(p.join(folder.path, 'project.json'))
        .writeAsString('{"id":"w1"}');
    final manuscript = File(
      p.join(folder.path, 'content', 'book', 'manuscript.md'),
    );
    await manuscript.parent.create(recursive: true);
    await manuscript.writeAsString('Texto inicial.');
    store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    controller = WorkspaceController(store, project, null);
    await controller.load();
  });

  tearDown(() async {
    controller.dispose();
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  test('começa na visão geral e não duplica abas', () {
    expect(controller.activeTabId, WorkspaceTab.overview.id);
    controller.openTab(WorkspaceTab.gallery);
    controller.openTab(WorkspaceTab.gallery);
    expect(controller.tabs.map((t) => t.id), ['overview', 'gallery']);
    expect(controller.activeTabId, 'gallery');
  });

  test('fechar a aba ativa ativa a vizinha e o fim deixa o editor vazio', () {
    controller
      ..openTab(WorkspaceTab.gallery)
      ..openTab(WorkspaceTab.settings);
    controller.closeTabNow('settings');
    expect(controller.activeTabId, 'gallery');
    controller
      ..closeTabNow('gallery')
      ..closeTabNow('overview');
    expect(controller.tabs, isEmpty);
    expect(controller.activeTabId, isNull);
  });

  test('editar marca a aba como suja e salvar grava o arquivo', () async {
    controller.openManuscript(null);
    final buffer = controller.bufferFor(null);
    expect(buffer.controller.text, 'Texto inicial.');
    buffer.controller.text = 'Texto novo.';
    controller.onBufferChanged(null);
    expect(controller.isDirty('manuscript'), isTrue);

    expect(await controller.saveBuffer('single'), isTrue);
    expect(controller.isDirty('manuscript'), isFalse);
    expect(
      await File(p.join(folder.path, 'content', 'book', 'manuscript.md'))
          .readAsString(),
      'Texto novo.',
    );
  });

  test(
    'canClose salva o manuscrito e respeita a trava de outras abas',
    () async {
      controller.openManuscript(null);
      controller.bufferFor(null).controller.text = 'Mudou.';
      controller.onBufferChanged(null);
      expect(await controller.canClose('manuscript'), isTrue);
      expect(store.book.singleText, 'Mudou.');

      controller.openTab(WorkspaceTab.settings);
      controller.setGuard('settings', () async => false);
      expect(await controller.canClose('settings'), isFalse);
      controller.setGuard('settings', () async => true);
      expect(await controller.canClose('settings'), isTrue);
    },
  );

  test('rascunho de elemento é trocado pela aba do elemento salvo', () {
    final draft = controller.newElementDraft();
    expect(WorkspaceTab.element(draft.split(':').last).isDraftElement, isTrue);
    controller.setDirty(draft, true);
    controller.promoteDraft(draft, 'lia');
    expect(controller.tabs.map((t) => t.id), ['overview', 'element:lia']);
    expect(controller.activeTabId, 'element:lia');
    expect(controller.isDirty(draft), isFalse);
  });

  test('converter para capítulos fecha o manuscrito único', () async {
    controller.openManuscript(null);
    await store.setChapterMode(true);
    controller.syncWithBook();
    expect(controller.tabs.any((t) => t.id == 'manuscript'), isFalse);
    controller.openManuscript(store.book.chapters.first.id);
    expect(controller.activeTab?.kind, WorkspaceTabKind.chapter);
    expect(
      controller.bufferFor(store.book.chapters.first.id).controller.text,
      contains('Texto inicial.'),
    );
  });

  test('painéis respeitam os limites de tamanho e a seleção alterna', () {
    controller.resizeSidePanel(1000);
    expect(controller.sidePanelWidth, WorkspaceLayout.maxSidePanelWidth);
    controller.resizeSidePanel(-1000);
    expect(controller.sidePanelWidth, WorkspaceLayout.minSidePanelWidth);
    controller.resizeInspector(-1000);
    expect(controller.inspectorWidth, WorkspaceLayout.maxInspectorWidth);

    controller.selectSection(WorkspaceSection.elements);
    expect(controller.sidePanel, WorkspaceSection.elements);
    controller.selectSection(WorkspaceSection.elements);
    expect(controller.sidePanel, isNull);
    controller.selectSection(WorkspaceSection.gallery);
    expect(controller.activeTabId, 'gallery');
  });
}
