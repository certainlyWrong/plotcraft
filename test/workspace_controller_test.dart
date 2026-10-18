import 'dart:convert';
import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/delta_edit.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'support/fake_fonts.dart';

/// Text of a buffer without the trailing newline Quill always keeps.
String textOf(DocumentBuffer buffer) =>
    buffer.controller.document.toPlainText().trim();

/// Replaces the whole text of a buffer, like the person typing over it.
void setText(DocumentBuffer buffer, String text) {
  final controller = buffer.controller;
  controller.replaceText(
    0,
    controller.document.length - 1,
    text,
    TextSelection.collapsed(offset: text.length),
  );
}

/// Lets the document's change stream deliver its events.
Future<void> pumpEvents() => Future<void>.delayed(Duration.zero);

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
    controller = WorkspaceController(store, project, null, testFontsStore());
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

  String firstChapter() => store.book.chapters.first.id;

  test('o manuscrito antigo vira o primeiro capítulo ao abrir o projeto', () {
    expect(store.book.chaptersEnabled, isTrue);
    expect(store.book.chapters, hasLength(1));
    expect(textOf(controller.bufferFor(firstChapter())), 'Texto inicial.');
  });

  test('editar marca a aba como suja e salvar grava o arquivo', () async {
    final id = firstChapter();
    controller.openManuscript(id);
    final buffer = controller.bufferFor(id);
    expect(textOf(buffer), 'Texto inicial.');
    expect(controller.isDirty('chapter:$id'), isFalse);
    // Typing in the editor marks the tab dirty without any extra call.
    setText(buffer, 'Texto novo.');
    await pumpEvents();
    expect(controller.isDirty('chapter:$id'), isTrue);

    expect(await controller.saveBuffer(id), isTrue);
    expect(controller.isDirty('chapter:$id'), isFalse);
    final book = p.join(folder.path, 'content', 'book', 'chapters');
    // The Markdown copy is derived from the Delta, which is the saved truth.
    expect(
      (await File(p.join(book, '$id.md')).readAsString()).trim(),
      'Texto novo.',
    );
    final delta = jsonDecode(
      await File(p.join(book, '$id.delta.json')).readAsString(),
    ) as Map<String, dynamic>;
    expect(delta['schemaVersion'], 1);
    expect(delta['ops'], [
      {'insert': 'Texto novo.\n'},
    ]);
  });

  test(
    'canClose salva o manuscrito e respeita a trava de outras abas',
    () async {
      final id = firstChapter();
      controller.openManuscript(id);
      setText(controller.bufferFor(id), 'Mudou.');
      expect(await controller.canClose('chapter:$id'), isTrue);
      expect(store.book.textFor(id).trim(), 'Mudou.');

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

  test(
    'adicionar, reordenar e remover capítulos mantém as abas coerentes',
    () async {
      final first = firstChapter();
      final second = await store.addChapter('Segundo');
      expect(second, isNotNull);
      controller
        ..openManuscript(first)
        ..openManuscript(second);
      setText(controller.bufferFor(second), 'Texto do segundo.');
      expect(await controller.saveAllBuffers(), isTrue);

      await store.updateChapters([
        store.book.chapters.last,
        store.book.chapters.first,
      ]);
      expect(store.book.chapters.map((c) => c.id), [second, first]);
      expect(store.book.textFor(second).trim(), 'Texto do segundo.');

      await store.removeChapter(first);
      controller.syncWithBook();
      expect(controller.tabs.any((t) => t.id == 'chapter:$first'), isFalse);
      expect(controller.tabs.any((t) => t.id == 'chapter:$second'), isTrue);
      expect(store.book.chapters.map((c) => c.id), [second]);
    },
  );

  group('mudanças feitas fora do app', () {
    Future<void> writeOutside(String id, String text) async {
      final outside = await StoryWorkspace.open(store.project!);
      await outside.writeChapter(id, Delta()..insert('$text\n'));
    }

    test('capítulo sem edições é atualizado sem marcar como sujo', () async {
      final id = firstChapter();
      controller.openManuscript(id);
      final buffer = controller.bufferFor(id);
      await writeOutside(id, 'Texto vindo da IA.');
      expect(await controller.reloadFromDisk(), isTrue);
      expect(textOf(buffer), 'Texto vindo da IA.');
      expect(controller.isDirty('chapter:$id'), isFalse);
      expect(controller.externalConflicts, isEmpty);
      expect(store.book.textFor(id).trim(), 'Texto vindo da IA.');
    });

    test(
      'a própria gravação do app não é tratada como mudança externa',
      () async {
        final id = firstChapter();
        controller.openManuscript(id);
        final buffer = controller.bufferFor(id);
        setText(buffer, 'Digitado aqui.');
        await controller.saveBuffer(id);
        expect(await controller.reloadFromDisk(), isTrue);
        expect(textOf(buffer), 'Digitado aqui.');
        expect(controller.externalConflicts, isEmpty);
      },
    );

    test(
      'com edições não salvas vira conflito e o autosave não sobrescreve',
      () async {
        final id = firstChapter();
        controller.openManuscript(id);
        final buffer = controller.bufferFor(id);
        setText(buffer, 'Minha edição.');
        await pumpEvents();
        await writeOutside(id, 'Edição de fora.');
        await controller.reloadFromDisk();
        expect(controller.externalConflicts, contains('chapter:$id'));
        expect(textOf(buffer), 'Minha edição.');
        expect(await controller.saveBuffer(id), isFalse);
        expect(
          (await StoryWorkspace.open(store.project!))
              .readChapter(id)
              .then((c) => DeltaEdit.text(c.delta)),
          completion('Edição de fora.\n'),
        );

        await controller.resolveExternalConflict(
          'chapter:$id',
          keepMine: false,
        );
        expect(textOf(buffer), 'Edição de fora.');
        expect(controller.externalConflicts, isEmpty);
        expect(controller.isDirty('chapter:$id'), isFalse);
      },
    );

    test('manter a minha versão grava por cima', () async {
      final id = firstChapter();
      controller.openManuscript(id);
      final buffer = controller.bufferFor(id);
      setText(buffer, 'Fica a minha.');
      await pumpEvents();
      await writeOutside(id, 'Perde a de fora.');
      await controller.reloadFromDisk();
      await controller.resolveExternalConflict('chapter:$id', keepMine: true);
      final onDisk = await (await StoryWorkspace.open(store.project!))
          .readChapter(id);
      expect(DeltaEdit.text(onDisk.delta), 'Fica a minha.\n');
      expect(controller.externalConflicts, isEmpty);
    });

    test('capítulo criado e removido por fora aparece e fecha a aba', () async {
      final outside = await StoryWorkspace.open(store.project!);
      final second = await outside.addChapter('Segundo');
      await controller.reloadFromDisk();
      expect(store.book.chapters.map((c) => c.id), contains(second));

      controller.openManuscript(second);
      await outside.removeChapter(second);
      await controller.reloadFromDisk();
      expect(controller.tabs.any((t) => t.id == 'chapter:$second'), isFalse);
    });

    test(
      'elemento alterado por fora recarrega a aba ou aponta conflito',
      () async {
        final outside = await StoryWorkspace.open(store.project!);
        final saved = await outside.saveElement(
          NarrativeElement(
            id: 'maria',
            typeId: 'character',
            title: 'Maria',
            summary: '',
            sections: const [],
            phases: const [],
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
        await controller.reloadFromDisk();
        expect(store.elements.map((e) => e.id), ['maria']);

        controller.openTab(WorkspaceTab.element('maria'));
        await outside.saveElement(saved.element.copyWith(summary: 'Mudou.'));
        await controller.reloadFromDisk();
        expect(controller.externalVersions['element:maria'], 1);

        controller.setDirty('element:maria', true);
        await outside.saveElement(
          saved.element.copyWith(summary: 'Mudou de novo.'),
        );
        await controller.reloadFromDisk();
        expect(controller.externalConflicts, contains('element:maria'));
        await controller.resolveExternalConflict(
          'element:maria',
          keepMine: false,
        );
        expect(controller.isDirty('element:maria'), isFalse);
        expect(controller.externalVersions['element:maria'], 2);

        await outside.removeElement('maria');
        await controller.reloadFromDisk();
        expect(controller.tabs.any((t) => t.id == 'element:maria'), isFalse);
      },
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
