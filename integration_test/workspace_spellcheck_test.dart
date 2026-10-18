import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/fonts/project_font_loader.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_files.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/workspace_shell.dart';
import 'package:plotcraft/features/project_workspace/presentation/workspace_actions.dart';
import 'package:plotcraft/features/project_workspace/stores/editor_fonts_store.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';

import '../tool/screenshots/sample_project.dart';

/// The real workspace with the real macOS spell checker:
/// `flutter test integration_test/workspace_spellcheck_test.dart -d macos`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workspace: corrigir uma palavra pelo menu grava no capítulo', (
    tester,
  ) async {
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('plotcraft-it-'),
    ))!;
    addTearDown(() => root.deleteSync(recursive: true));
    final project = (await tester.runAsync(() => buildSampleBook(root)))!;

    final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
    final controller = WorkspaceController(
      store,
      project,
      null,
      EditorFontsStore(
        const ProjectFontsRepository(ProjectFiles()),
        const ProjectFontLoader(),
        const PlatformSystemFontLister(),
      ),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.load);
    final actions = WorkspaceActions(controller);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('pt'),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: [
              ...context.localizationDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            home: WorkspaceShell(
              project: project,
              controller: controller,
              actions: actions,
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    Future<void> wait(int ms) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );
      await tester.pump(Duration(milliseconds: ms));
    }

    await wait(800);
    final chapterId = store.book.chapters.first.id;
    controller.openManuscript(chapterId);
    await wait(800);

    // Type a misspelled word the way the editor would receive it.
    final quill = controller.bufferFor(chapterId).controller;
    quill.replaceText(
      0,
      0,
      'Um errro aqui. ',
      const TextSelection.collapsed(offset: 15),
    );
    for (var i = 0; i < 15; i++) {
      await wait(200);
    }

    final line = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('errro'),
    );
    expect(line, findsWidgets);
    final paragraph = tester.renderObject<RenderParagraph>(line.first);
    final at = paragraph.text.toPlainText().indexOf('errro');
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: at, extentOffset: at + 5),
        )
        .first;
    await tester.tapAt(
      paragraph.localToGlobal(box.toRect().center),
      buttons: kSecondaryButton,
    );
    for (var i = 0; i < 10; i++) {
      await wait(200);
    }
    final menu = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    // ignore: avoid_print
    print('WORKSPACE MENU $menu');
    expect(menu, contains('erro'), reason: 'sem sugestão no menu: $menu');

    await tester.tap(find.text('erro'));
    await wait(400);
    expect(quill.document.toPlainText(), startsWith('Um erro aqui.'));
    expect(controller.isDirty('chapter:$chapterId'), isTrue);

    // The autosave writes the corrected chapter.
    for (var i = 0; i < 20 && controller.isDirty('chapter:$chapterId'); i++) {
      await wait(300);
    }
    expect(controller.isDirty('chapter:$chapterId'), isFalse);
    final saved = await tester.runAsync(
      () => File(
        p.join(
          project.directoryPath!,
          'content',
          'book',
          'chapters',
          '$chapterId.delta.json',
        ),
      ).readAsString(),
    );
    expect(saved, contains('Um erro aqui.'));
    await tester.pumpWidget(const SizedBox());
    await wait(500);
  });
}
