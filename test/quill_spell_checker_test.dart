import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/spellcheck/quill_spell_checker.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';

/// Flags every occurrence of the words in [wrong] and counts the calls.
class FakeBackend implements SpellCheckBackend {
  FakeBackend(this.wrong);

  final Set<String> wrong;
  int checks = 0;
  final learned = <String>[];
  Duration delay = Duration.zero;

  @override
  Future<List<Misspelling>> check(String text, Locale locale) async {
    checks++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final found = <Misspelling>[];
    for (final match in RegExp(r'\S+').allMatches(text)) {
      if (wrong.contains(match.group(0))) {
        found.add(Misspelling(match.start, match.end));
      }
    }
    return found;
  }

  @override
  Future<List<String>> suggest(String word, Locale locale) async => [
    word == 'errro' ? 'erro' : '$word?',
  ];

  @override
  Future<void> learn(String word) async {
    learned.add(word);
    wrong.remove(word);
  }
}

QuillController _controller(String text) => QuillController(
  // Loaded like a saved chapter, so undo cannot go back before the text.
  document: Document.fromJson([
    {'insert': '$text\n'},
  ]),
  selection: const TextSelection.collapsed(offset: 0),
);

Future<void> _pumpEditor(
  WidgetTester tester,
  QuillController controller,
  QuillSpellChecker checker,
) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: checker,
          builder: (context, _) => QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              textSpanBuilder: checker.spanBuilder,
              contextMenuBuilder: checker.buildContextMenu,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Text of every wavy-underlined span currently painted by the editor.
List<String> _underlined(WidgetTester tester) {
  final result = <String>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style?.decorationStyle == TextDecorationStyle.wavy &&
          span.text != null) {
        result.add(span.text!);
      }
      span.children?.forEach(visit);
    }
  }

  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    visit(rich.text);
  }
  return result;
}

/// Stops the checker and lets pending timers run out before the test ends.
Future<void> _finish(WidgetTester tester, QuillSpellChecker checker) async {
  checker.detach();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  benchmark();
  late FakeBackend backend;
  late QuillSpellChecker checker;
  late QuillController controller;

  setUp(() {
    backend = FakeBackend({'errro', 'pasagem'});
    checker = QuillSpellChecker(
      backend: backend,
      locale: const Locale('pt', 'BR'),
      debounce: const Duration(milliseconds: 100),
    );
    controller = _controller('Um errro na pasagem do texto');
  });

  tearDown(() {
    checker.dispose();
    controller.dispose();
  });

  testWidgets('sublinha só as palavras erradas, sem tocar no documento', (
    tester,
  ) async {
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    expect(_underlined(tester), isEmpty);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(checker.misspellings.map((m) => (m.start, m.end)), [
      (3, 8),
      (12, 19),
    ]);
    expect(_underlined(tester), ['errro', 'pasagem']);

    // The underline is paint only: the saved Delta has no trace of it.
    final json = controller.document.toDelta().toJson().toString();
    expect(json, isNot(contains('underline')));
    expect(json, isNot(contains('wavy')));
    await _finish(tester, checker);
  });

  testWidgets('o sublinhado acompanha a palavra quando se digita antes dela', (
    tester,
  ) async {
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    controller.replaceText(
      0,
      0,
      'Texto novo. ',
      const TextSelection.collapsed(offset: 12),
    );
    await tester.pump();
    // Right after the edit, before the next check, the ranges already moved.
    expect(checker.misspellings.first.start, 15);
    expect(_underlined(tester), ['errro', 'pasagem']);
    await _finish(tester, checker);
  });

  testWidgets(
    'resultado antigo é descartado quando o texto muda durante a checagem',
    (tester) async {
      backend.delay = const Duration(milliseconds: 200);
      checker.attach(controller);
      await _pumpEditor(tester, controller, checker);
      await tester.pump(const Duration(milliseconds: 120)); // check #1 starts
      controller.replaceText(
        0,
        0,
        'Oi ',
        const TextSelection.collapsed(offset: 3),
      );
      await tester.pump(const Duration(milliseconds: 100)); // check #2 starts
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(backend.checks, 2);
      // Only the answer for the edited text counts: offsets include "Oi ".
      expect(checker.misspellings.first.start, 6);
      await _finish(tester, checker);
    },
  );

  testWidgets(
    'menu de contexto: sugestão substitui a palavra em uma única edição',
    (tester) async {
      checker.attach(controller);
      await _pumpEditor(tester, controller, checker);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      final target = checker.misspellings.first;
      checker.replaceMisspelling(target, 'erro');
      await tester.pump();
      expect(
        controller.document.toPlainText(),
        startsWith('Um erro na pasagem'),
      );

      controller.undo();
      await tester.pump();
      expect(
        controller.document.toPlainText(),
        startsWith('Um errro na pasagem'),
      );
      await _finish(tester, checker);
    },
  );

  testWidgets('clique direito na palavra e escolha da sugestão no menu', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    final origin = tester.getTopLeft(find.byType(QuillEditor));
    // "Um errro": the word starts after three characters of default text.
    await tester.tapAt(
      origin + const Offset(45, 14),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print(
      'SEL ${controller.selection} TEXTS ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}',
    );
    debugDefaultTargetPlatformOverride = null;
    expect(find.text('erro'), findsOneWidget);
    await tester.tap(find.text('erro'));
    await tester.pumpAndSettle();
    expect(controller.document.toPlainText(), startsWith('Um erro na pasagem'));
    await _finish(tester, checker);
  });

  testWidgets('"adicionar ao dicionário" ensina a palavra e refaz a checagem', (
    tester,
  ) async {
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    await tester.runAsync(() => checker.learn('errro'));
    await tester.pump();
    expect(backend.learned, ['errro']);
    expect(checker.misspellings.map((m) => (m.start, m.end)), [(12, 19)]);
    await _finish(tester, checker);
  });

  testWidgets('desligar o corretor limpa os sublinhados e para as checagens', (
    tester,
  ) async {
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    checker.enabled = false;
    await tester.pump();
    expect(_underlined(tester), isEmpty);
    final before = backend.checks;
    controller.replaceText(0, 0, 'x', const TextSelection.collapsed(offset: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(backend.checks, before);
    await _finish(tester, checker);
  });

  testWidgets('texto formatado: o sublinhado convive com negrito e cor', (
    tester,
  ) async {
    controller.formatText(3, 5, Attribute.bold);
    controller.formatText(12, 7, ColorAttribute('#ff0000'));
    checker.attach(controller);
    await _pumpEditor(tester, controller, checker);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(_underlined(tester), ['errro', 'pasagem']);
    final styles = <TextStyle?>[];
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      void visit(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text == 'errro') styles.add(span.style);
          span.children?.forEach(visit);
        }
      }

      visit(rich.text);
    }
    expect(styles.single?.fontWeight, FontWeight.bold);
    await _finish(tester, checker);
  });
}

/// Measures the cost of underlines on a long chapter. The editor lays out
/// every paragraph, so this is the realistic worst case for one document.
void benchmark() {
  testWidgets('desempenho: 10 mil palavras com mais de mil erros', (
    tester,
  ) async {
    final words = 'a corredora chegou na pista de sal e sentiu o vento correndo errro pasagem'
        .split(' ');
    final paragraphs = <String>[];
    var index = 0;
    for (var p = 0; p < 100; p++) {
      final line = <String>[];
      for (var w = 0; w < 100; w++) {
        line.add(words[index++ % words.length]);
      }
      paragraphs.add(line.join(' '));
    }
    final text = paragraphs.join('\n');
    final slow = FakeBackend({'errro', 'pasagem'});
    final long = QuillSpellChecker(
      backend: slow,
      locale: const Locale('pt', 'BR'),
      debounce: const Duration(milliseconds: 50),
    );
    final doc = _controller(text);
    addTearDown(doc.dispose);

    final plain = Stopwatch()..start();
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuillEditor.basic(controller: doc)),
      ),
    );
    plain.stop();

    long.attach(doc);
    final withSpans = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: long,
            builder: (context, _) => QuillEditor.basic(
              controller: doc,
              config: QuillEditorConfig(textSpanBuilder: long.spanBuilder),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    withSpans.stop();
    final flagged = long.misspellings.length;
    // ignore: avoid_print
    print(
      'BENCH words=${text.split(RegExp(r'\s+')).length} flagged=$flagged '
      'plain=${plain.elapsedMilliseconds}ms withSpans=${withSpans.elapsedMilliseconds}ms',
    );
    expect(flagged, greaterThan(1000));

    // One keystroke: ranges are moved and the editor repaints.
    final typing = Stopwatch()..start();
    doc.replaceText(0, 0, 'x', const TextSelection.collapsed(offset: 1));
    await tester.pump();
    typing.stop();
    // ignore: avoid_print
    print('BENCH keystroke=${typing.elapsedMilliseconds}ms');
    await _finish(tester, long);
    long.dispose();
  });
}
