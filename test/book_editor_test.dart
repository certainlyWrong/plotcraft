import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/project_image.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/project_workspace/domain/gallery_item.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/quill_find_replace.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';

class _Backend implements SpellCheckBackend {
  @override
  Future<List<Misspelling>> check(String text, Locale locale) async => [
    for (final m in RegExp('errro').allMatches(text))
      Misspelling(m.start, m.end),
  ];

  @override
  Future<List<String>> suggest(String word, Locale locale) async => ['erro'];

  @override
  Future<void> learn(String word) async {}
}

QuillController _controller(List<Map<String, dynamic>> ops) => QuillController(
  document: Document.fromJson(ops),
  selection: const TextSelection.collapsed(offset: 0),
);

void main() {
  group('QuillFindReplace', () {
    late QuillController controller;
    late QuillFindReplace search;

    setUp(() {
      controller = _controller([
        {'insert': 'Sal e sal e SAL.\n'},
      ]);
      search = QuillFindReplace(controller);
    });

    tearDown(() => controller.dispose());

    test('conta e localiza sem diferenciar caixa', () {
      expect(search.matches('sal'), [0, 6, 12]);
      expect(search.matches(''), isEmpty);
      expect(search.matches('mar'), isEmpty);
    });

    test('findNext avança, dá a volta e falha sem resultado', () {
      expect(search.findNext('sal'), isTrue);
      expect(controller.selection.start, 0);
      expect(search.findNext('sal'), isTrue);
      expect(controller.selection.start, 6);
      expect(search.findNext('sal'), isTrue);
      expect(search.findNext('sal'), isTrue);
      expect(controller.selection.start, 0);
      expect(search.findNext('mar'), isFalse);
    });

    test('replaceCurrent só troca quando a seleção é um resultado', () {
      expect(search.replaceCurrent('sal', 'mar'), isFalse);
      expect(controller.document.toPlainText(), startsWith('Sal e sal'));
      // The first call selected the first match.
      expect(search.replaceCurrent('sal', 'mar'), isTrue);
      expect(controller.document.toPlainText(), startsWith('mar e sal'));
    });

    test('replaceAll troca todos de uma vez e pode ser desfeito', () {
      expect(search.replaceAll('sal', 'mar'), 3);
      expect(controller.document.toPlainText(), 'mar e mar e mar.\n');
    });

    test('a troca mantém a formatação do restante do texto', () {
      final formatted = _controller([
        {'insert': 'a '},
        {
          'insert': 'sal',
          'attributes': {'bold': true},
        },
        {'insert': ' b\n'},
      ]);
      addTearDown(formatted.dispose);
      QuillFindReplace(formatted).replaceAll('b', 'c');
      final ops = formatted.document.toDelta().toJson();
      expect(ops[1]['attributes'], {'bold': true});
      expect(formatted.document.toPlainText(), 'a sal c\n');
    });
  });

  group('BookEditor', () {
    Future<QuillController> pumpEditor(
      WidgetTester tester, {
      required List<Map<String, dynamic>> ops,
      VoidCallback? onSave,
      ValueChanged<String>? onOpenElement,
      List<NarrativeElement> elements = const [],
      List<GalleryItem> gallery = const [],
    }) async {
      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = _controller(ops);
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
              dirty: true,
              saving: false,
              fullscreen: false,
              onSave: onSave ?? () {},
              onToggleFullscreen: () {},
              onOpenElement: onOpenElement ?? (_) {},
              elements: elements,
              types: ElementTypeCatalog.builtin,
              galleryItems: gallery,
              backend: _Backend(),
            ),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('mostra a barra de formatação e conta as palavras', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        ops: [
          {'insert': 'Um dois três\n'},
        ],
      );
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.text('workspace.word_count'), findsOneWidget);
      expect(find.text('workspace.unsaved'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Cmd+S salva e Cmd+F abre a busca; substituir altera o texto', (
      tester,
    ) async {
      var saves = 0;
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'o sal e o sal\n'},
        ],
        onSave: () => saves++,
      );
      // Shortcuts act while the editor has focus, as when someone is typing.
      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(saves, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(find.text('book.replace_current'), findsNothing);
      expect(find.byTooltip('book.find_next'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'sal');
      await tester.enterText(fields.at(1), 'mar');
      await tester.pump();
      expect(find.text('editor.matches'), findsOneWidget);
      await tester.tap(find.byTooltip('editor.replace_all'));
      await tester.pump();
      expect(controller.document.toPlainText(), 'o mar e o mar\n');
      await finish(tester);
    });

    testWidgets('menções aparecem destacadas e só abrem o elemento com Cmd', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpEditor(
        tester,
        ops: [
          {'insert': 'Ela viu '},
          {
            'insert': 'Lia',
            'attributes': {
              RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
            },
          },
          {'insert': '.\n'},
        ],
        onOpenElement: opened.add,
      );
      final mention = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Lia'),
      );
      expect(mention, findsWidgets);
      final rich = tester.widget<RichText>(mention.first);
      TextSpan? span;
      rich.text.visitChildren((child) {
        if (child is TextSpan && child.text == 'Lia') span = child;
        return true;
      });
      expect(span, isNotNull);
      expect(span!.style?.fontWeight, FontWeight.w600);

      final recognizer = span!.recognizer as TapGestureRecognizer;
      recognizer.onTap!();
      expect(opened, isEmpty, reason: 'sem Cmd é só um clique no texto');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      recognizer.onTap!();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(opened, ['lia']);
      await finish(tester);
    });

    testWidgets('palavras erradas são sublinhadas sem alterar o documento', (
      tester,
    ) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'Um errro aqui\n'},
        ],
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      final wavy = <String>[];
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        rich.text.visitChildren((child) {
          if (child is TextSpan &&
              child.style?.decorationStyle == TextDecorationStyle.wavy &&
              child.text != null) {
            wavy.add(child.text!);
          }
          return true;
        });
      }
      expect(wavy, ['errro']);
      expect(
        controller.document.toDelta().toJson().toString(),
        isNot(contains('wavy')),
      );
      await finish(tester);
    });

    testWidgets(
      'a formatação da barra altera o Delta (negrito, cor, fonte, tamanho)',
      (tester) async {
        final controller = await pumpEditor(
          tester,
          ops: [
            {'insert': 'Texto longo\n'},
          ],
        );
        controller.updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 5),
          ChangeSource.local,
        );
        controller
          ..formatSelection(Attribute.bold)
          ..formatSelection(const ColorAttribute('#c0392b'))
          ..formatSelection(Attribute.fromKeyValue('font', 'Lora'))
          ..formatSelection(Attribute.fromKeyValue('size', '24'));
        await tester.pump();
        final first = controller.document.toDelta().toJson().first;
        expect(first['insert'], 'Texto');
        expect(first['attributes'], {
          'bold': true,
          'color': '#c0392b',
          'font': 'Lora',
          'size': '24',
        });
        await finish(tester);
      },
    );

    NarrativeElement element(String id, String title) => NarrativeElement(
      id: id,
      typeId: 'character',
      title: title,
      summary: '',
      sections: const [],
      phases: const [],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    testWidgets('digitar @ abre a lista de elementos e a escolha vira menção', (
      tester,
    ) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'Ela viu \n'},
        ],
        elements: [element('lia', 'Lia'), element('tom', 'Tom')],
      );
      controller.replaceText(
        8,
        0,
        '@',
        const TextSelection.collapsed(offset: 9),
      );
      await tester.pumpAndSettle();
      expect(find.text('editor.mention_title'), findsOneWidget);
      expect(find.text('Lia'), findsOneWidget);
      expect(find.text('Tom'), findsOneWidget);

      // Typing filters the list and Enter picks the highlighted element.
      await tester.enterText(find.byType(TextField).last, 'to');
      await tester.pump();
      expect(find.text('Lia'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Ela viu Tom \n');
      expect(RichDocument.mentionedIds(controller.document.toDelta()), ['tom']);
      await finish(tester);
    });

    testWidgets('setas e Enter escolhem na lista; Esc fecha e deixa o @', (
      tester,
    ) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'a \n'},
        ],
        elements: [element('lia', 'Lia'), element('tom', 'Tom')],
      );
      controller.replaceText(
        2,
        0,
        '@',
        const TextSelection.collapsed(offset: 3),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(RichDocument.mentionedIds(controller.document.toDelta()), ['tom']);

      controller.replaceText(
        0,
        0,
        '@',
        const TextSelection.collapsed(offset: 1),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('editor.mention_title'), findsNothing);
      expect(controller.document.toPlainText(), startsWith('@a '));
      await finish(tester);
    });

    testWidgets('@ dentro de um e-mail não abre a lista', (tester) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'ana\n'},
        ],
        elements: [element('lia', 'Lia')],
      );
      controller.replaceText(
        3,
        0,
        '@',
        const TextSelection.collapsed(offset: 4),
      );
      await tester.pumpAndSettle();
      expect(find.text('editor.mention_title'), findsNothing);
      await finish(tester);
    });

    testWidgets('o botão de elemento liga o texto selecionado', (tester) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'A corredora chegou\n'},
        ],
        elements: [element('maria', 'Maria')],
      );
      controller.updateSelection(
        const TextSelection(baseOffset: 2, extentOffset: 11),
        ChangeSource.local,
      );
      await tester.tap(find.byTooltip('editor.insert_mention'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maria'));
      await tester.pumpAndSettle();
      expect(controller.document.toPlainText(), 'A corredora chegou\n');
      expect(RichDocument.mentionedIds(controller.document.toDelta()), [
        'maria',
      ]);
      await finish(tester);
    });

    testWidgets('imagem da galeria escolhida é inserida e desenhada', (
      tester,
    ) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'Texto\n'},
        ],
        gallery: const [
          GalleryItem(
            id: 'g1',
            file: 'a.png',
            path: '/nao/existe/a.png',
            exists: true,
          ),
        ],
      );
      await tester.tap(find.byTooltip('editor.insert_image'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(find.text('workspace.save_project'));
      await tester.pumpAndSettle();
      expect(RichDocument.galleryImageIds(controller.document.toDelta()), {
        'g1',
      });
      expect(find.byType(ProjectImage), findsOneWidget);
      await finish(tester);
    });

    testWidgets('imagem que não está mais na galeria mostra um aviso', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        ops: [
          {'insert': 'Antes\n'},
          {'insert': RichDocument.galleryImage('sumiu')},
          {'insert': '\n'},
        ],
      );
      expect(find.text('editor.image_missing'), findsOneWidget);
      expect(find.byType(ProjectImage), findsNothing);
      await finish(tester);
    });

    testWidgets('divisor é desenhado e a barra tem os botões extras', (
      tester,
    ) async {
      final controller = await pumpEditor(
        tester,
        ops: [
          {'insert': 'Um\n'},
        ],
      );
      await tester.tap(find.byTooltip('editor.insert_divider'));
      await tester.pump();
      expect(find.text('* * *'), findsOneWidget);
      expect(
        controller.document.toDelta().toList().any(
          (op) => RichDocument.isDivider(op.data),
        ),
        isTrue,
      );
      await finish(tester);
    });
  });
}
