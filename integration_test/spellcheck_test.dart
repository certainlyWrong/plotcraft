import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plotcraft/core/spellcheck/quill_spell_checker.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';

/// Runs the real macOS spell checker (`flutter test integration_test -d macos`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clique direito numa palavra errada e escolher a sugestão', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'The runnre arrived early.\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    final checker = QuillSpellChecker(
      backend: const MethodChannelSpellCheckBackend(),
      locale: const Locale('en', 'US'),
      debounce: const Duration(milliseconds: 100),
    );
    addTearDown(() {
      checker.dispose();
      controller.dispose();
    });
    checker.attach(controller);
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
    // The native check answers asynchronously, outside the fake clock.
    for (var i = 0; i < 30 && checker.misspellings.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(checker.misspellings, isNotEmpty, reason: 'nothing was flagged');
    final flagged = checker.misspellings.first;
    expect(flagged.start, 4);

    final line = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('runnre'),
    );
    final rect = tester.getRect(line.first);
    await tester.tapAt(
      rect.topLeft + const Offset(45, 8),
      buttons: kSecondaryButton,
    );
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final menu = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    // ignore: avoid_print
    print('MENU $menu');
    final suggestion = menu.firstWhere(
      (label) =>
          label != 'Add to dictionary' && label.toLowerCase() == 'runner',
      orElse: () => '',
    );
    expect(suggestion, isNotEmpty, reason: 'no "runner" suggestion: $menu');
    await tester.tap(find.text(suggestion));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.document.toPlainText(), startsWith('The runner arrived'));
  });

  testWidgets('BookEditor completo: sugestão do menu é aplicada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'Chapter'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
        {'insert': 'The runnre arrived early.\n'},
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
            elements: const [],
            types: ElementTypeCatalog.builtin,
            galleryItems: const [],
            backend: const MethodChannelSpellCheckBackend(),
          ),
        ),
      ),
    );
    final line = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('runnre'),
    );
    for (var i = 0; i < 40 && line.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Let the native check mark the word.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final rect = tester.getRect(line.first);
    await tester.tapAt(
      rect.topLeft + const Offset(45, 8),
      buttons: kSecondaryButton,
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final menu = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    // ignore: avoid_print
    print('BOOK MENU $menu SEL ${controller.selection}');
    expect(menu, contains('runner'));
    await tester.tap(find.text('runner'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.document.toPlainText(), contains('The runner arrived'));
  });
}
