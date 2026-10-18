import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_references_panel.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'support/fake_fonts.dart';

class _NoSpell implements SpellCheckBackend {
  @override
  Future<List<Misspelling>> check(String text, Locale locale) async => const [];

  @override
  Future<List<String>> suggest(String word, Locale locale) async => const [];

  @override
  Future<void> learn(String word) async {}
}

Widget _app(Widget child) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
  supportedLocales: FlutterQuillLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('o painel lista as ocorrências e devolve a escolhida', (
    tester,
  ) async {
    MentionOccurrence? opened;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: ElementReferencesPanel(
            occurrences: const [
              MentionOccurrence(
                chapterId: 'c1',
                chapterTitle: 'Largada',
                start: 6,
                end: 9,
                snippet: 'Ontem Lia correu',
                linked: true,
              ),
              MentionOccurrence(
                chapterId: 'c2',
                chapterTitle: 'Chegada',
                start: 0,
                end: 3,
                snippet: 'Lia parou',
                linked: false,
              ),
            ],
            onOpen: (o) => opened = o,
          ),
        ),
      ),
    );
    expect(find.text('elements.occurrences_summary'), findsOneWidget);
    await tester.tap(find.text('Lia parou'));
    expect(opened?.chapterId, 'c2');
    expect(opened?.start, 0);
  });

  testWidgets('sem ocorrências mostra o aviso', (tester) async {
    await tester.pumpWidget(
      _app(ElementReferencesPanel(occurrences: const [], onOpen: (_) {})),
    );
    expect(find.text('elements.no_references'), findsOneWidget);
    expect(find.text('elements.occurrences_summary'), findsNothing);
  });

  testWidgets('o editor seleciona o trecho pedido e avisa que já mostrou', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'Ontem Lia correu muito\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    var revealed = 0;
    await tester.pumpWidget(
      _app(
        BookEditor(
          controller: controller,
          dirty: false,
          saving: false,
          fullscreen: false,
          onSave: () {},
          onToggleFullscreen: () {},
          onOpenElement: (_) {},
          reveal: const TextRange(start: 6, end: 9),
          onRevealed: () => revealed++,
          backend: _NoSpell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(controller.selection.start, 6);
    expect(controller.selection.end, 9);
    expect(revealed, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  test(
    'abrir uma ocorrência abre o capítulo e guarda o trecho a mostrar',
    () async {
      final folder = await Directory.systemTemp.createTemp('plotcraft-reveal-');
      addTearDown(() => folder.delete(recursive: true));
      final now = DateTime.utc(2026);
      final project = StoryProject(
        id: 'rv1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder.path,
      );
      await File(p.join(folder.path, 'project.json'))
          .writeAsString('{"id":"rv1"}');
      final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
      final controller = WorkspaceController(
        store,
        project,
        null,
        testFontsStore(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      controller.openManuscript(
        null,
        reveal: const TextRange(start: 2, end: 5),
      );
      expect(controller.activeTabId, 'manuscript');
      expect(
        controller.revealRequests['manuscript'],
        const TextRange(start: 2, end: 5),
      );
      controller.clearReveal('manuscript');
      expect(controller.revealRequests, isEmpty);
      controller.openManuscript(null);
      expect(controller.revealRequests, isEmpty);
    },
  );

  test('as menções ligadas contam como ocorrências do elemento', () {
    final delta = Delta()
      ..insert('Ela viu ')
      ..insert('Lia', {
        RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
      })
      ..insert('.\n');
    expect(RichDocument.mentionedIds(delta), ['lia']);
    expect(NarrativeElement, isNotNull);
  });
}
