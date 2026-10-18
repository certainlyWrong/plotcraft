import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/domain/active_phase.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/element_hover_card.dart';

class _NoSpell implements SpellCheckBackend {
  @override
  Future<List<Misspelling>> check(String text, Locale locale) async => const [];

  @override
  Future<List<String>> suggest(String word, Locale locale) async => const [];

  @override
  Future<void> learn(String word) async {}
}

NarrativeElement _lia({List<NarrativePhase> phases = const []}) =>
    NarrativeElement(
      id: 'lia',
      typeId: 'character',
      title: 'Lia',
      summary: 'Treinadora e amiga de Maria.',
      sections: const [],
      phases: phases,
      fields: const {'occupation': 'Treinadora'},
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  group('activePhaseAt', () {
    final order = ['c1', 'c2', 'c3'];
    NarrativePhase phase(String id, NarrativeAnchor anchor) =>
        NarrativePhase(id: id, title: id, description: '', anchor: anchor);

    test('escolhe a última fase ancorada até o capítulo atual', () {
      final element = _lia(
        phases: [
          phase('a', const NarrativeAnchor.chapter('c1')),
          phase('b', const NarrativeAnchor.chapter('c3')),
          phase('livre', const NarrativeAnchor.manual('depois da guerra')),
        ],
      );
      expect(activePhaseAt(element, order, 'c1')?.id, 'a');
      expect(activePhaseAt(element, order, 'c2')?.id, 'a');
      expect(activePhaseAt(element, order, 'c3')?.id, 'b');
    });

    test('sem fase aplicável ou sem capítulo devolve null', () {
      final element = _lia(
        phases: [phase('b', const NarrativeAnchor.chapter('c3'))],
      );
      expect(activePhaseAt(element, order, 'c1'), isNull);
      expect(activePhaseAt(element, order, null), isNull);
      expect(activePhaseAt(element, order, 'fora'), isNull);
    });
  });

  testWidgets('passar o mouse numa menção mostra o cartão do elemento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'Ela viu '},
        {
          'insert': 'Lia',
          'attributes': {
            RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
          },
        },
        {'insert': ' correr.\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: Scaffold(
          body: BookEditor(
            controller: controller,
            dirty: false,
            saving: false,
            fullscreen: false,
            onSave: () {},
            onToggleFullscreen: () {},
            onOpenElement: (_) {},
            elements: [_lia()],
            types: ElementTypeCatalog.builtin,
            backend: _NoSpell(),
          ),
        ),
      ),
    );
    await tester.pump();

    final line = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Lia'),
    );
    final paragraph = tester.renderObject<RenderParagraph>(line.first);
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 8, extentOffset: 11),
        )
        .first;
    final target = paragraph.localToGlobal(box.toRect().center);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(target);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ElementHoverCard), findsNothing, reason: 'cedo demais');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ElementHoverCard), findsOneWidget);
    expect(find.text('Treinadora e amiga de Maria.'), findsOneWidget);
    expect(find.textContaining('Treinadora'), findsWidgets);

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(find.byType(ElementHoverCard), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
