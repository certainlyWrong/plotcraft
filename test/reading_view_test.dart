import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/presentation/reading/reading_view.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';

const _chapters = [
  BookChapter(id: 'c1', title: 'Primeiro'),
  BookChapter(id: 'c2', title: 'Segundo'),
  BookChapter(id: 'c3', title: 'Terceiro'),
];

Delta _delta(String? id) => Delta.fromJson([
  {'insert': 'Texto do capítulo ${id ?? 'único'}.\n'},
]);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<BookChapter> chapters = _chapters,
    String? jumpTo,
    Map<String, Object?>? initialState,
    ValueChanged<Map<String, Object?>>? onStateChanged,
    ValueChanged<String?>? onEdit,
    ValueChanged<String>? onOpenElement,
    Delta Function(String?)? deltaFor,
  }) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: Scaffold(
          body: ReadingView(
            chapters: chapters,
            deltaFor: deltaFor ?? _delta,
            title: 'Livro',
            fullscreen: false,
            onToggleFullscreen: () {},
            onOpenElement: onOpenElement ?? (_) {},
            onEdit: onEdit,
            jumpTo: jumpTo,
            initialState: initialState,
            onStateChanged: onStateChanged,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  QuillController quill(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

  testWidgets('abre no primeiro capítulo, somente leitura', (tester) async {
    await pump(tester);
    expect(find.text('Primeiro'), findsWidgets);
    expect(quill(tester).readOnly, isTrue);
    expect(quill(tester).document.toPlainText(), 'Texto do capítulo c1.\n');
    expect(find.byType(QuillSimpleToolbar), findsNothing);
    await finish(tester);
  });

  testWidgets('as setas e os botões trocam de capítulo', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(quill(tester).document.toPlainText(), contains('c2'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(quill(tester).document.toPlainText(), contains('c3'));
    // No último capítulo não há "próximo" e aparece o fim.
    expect(find.text('reading.the_end'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(quill(tester).document.toPlainText(), contains('c3'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(quill(tester).document.toPlainText(), contains('c2'));
    await finish(tester);
  });

  testWidgets('retoma onde parou e respeita o pedido de salto', (tester) async {
    await pump(tester, initialState: {'chapter': 'c2', 'size': 22.0});
    expect(quill(tester).document.toPlainText(), contains('c2'));
    await finish(tester);

    await pump(tester, initialState: {'chapter': 'c2'}, jumpTo: 'c3');
    expect(quill(tester).document.toPlainText(), contains('c3'));
    await finish(tester);
  });

  testWidgets('guarda o capítulo e o tamanho do texto', (tester) async {
    Map<String, Object?>? saved;
    await pump(tester, onStateChanged: (state) => saved = state);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.tap(find.byTooltip('reading.larger'));
    await tester.pump(const Duration(seconds: 1));
    expect(saved, {'chapter': 'c2', 'size': ReadingView.defaultTextSize + 1});
    await finish(tester);
  });

  testWidgets('editar abre o capítulo que está sendo lido', (tester) async {
    String? edited;
    await pump(tester, onEdit: (id) => edited = id);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.tap(find.byTooltip('reading.edit'));
    expect(edited, 'c2');
    await finish(tester);
  });

  testWidgets('livro sem capítulos mostra o texto único', (tester) async {
    await pump(tester, chapters: const []);
    expect(quill(tester).document.toPlainText(), 'Texto do capítulo único.\n');
    expect(find.text('Livro'), findsWidgets);
    expect(find.text('reading.next'), findsNothing);
    await finish(tester);
  });

  testWidgets('clicar numa menção abre o elemento', (tester) async {
    String? opened;
    await pump(
      tester,
      onOpenElement: (id) => opened = id,
      deltaFor: (_) => Delta.fromJson([
        {'insert': 'Ela viu '},
        {
          'insert': 'Lia',
          'attributes': {
            RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
          },
        },
        {'insert': ' correr.\n'},
      ]),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.textContaining('Ela viu', findRichText: true).first,
    );
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 8, extentOffset: 11),
        )
        .first;
    await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 'lia');
    await finish(tester);
  });
}
