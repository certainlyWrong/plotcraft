import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/fonts/editor_font_catalog.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/data/project_files.dart';
import 'package:plotcraft/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/book_editor.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

import 'support/fake_fonts.dart';

class _NoSpell implements SpellCheckBackend {
  @override
  Future<List<Misspelling>> check(String text, Locale locale) async => const [];

  @override
  Future<List<String>> suggest(String word, Locale locale) async => const [];

  @override
  Future<void> learn(String word) async {}
}

void main() {
  group('EditorFontCatalog', () {
    const catalog = EditorFontCatalog(
      bundled: ['Lora', 'Roboto'],
      project: ['Garamond Premier'],
      system: ['Arial', 'lora', 'Georgia'],
      projectKey: 'abc',
    );

    test('o menu junta empacotadas, do projeto e do sistema sem repetir', () {
      expect(catalog.menuItems.keys.toList(), [
        'Lora',
        'Roboto',
        'Garamond Premier',
        'Arial',
        'Georgia',
      ]);
    });

    test('sabe de onde vem cada fonte, sem diferenciar caixa', () {
      expect(catalog.sourceOf('lora'), EditorFontSource.bundled);
      expect(catalog.sourceOf('garamond premier'), EditorFontSource.project);
      expect(catalog.sourceOf('Georgia'), EditorFontSource.system);
      expect(catalog.sourceOf('Papyrus'), isNull);
    });

    test('só as fontes do projeto são desenhadas com o nome registrado', () {
      expect(
        catalog.resolve('Garamond Premier'),
        'project:abc:Garamond Premier',
      );
      expect(
        catalog.resolve('garamond premier'),
        'project:abc:Garamond Premier',
      );
      expect(catalog.resolve('Lora'), 'Lora');
      expect(catalog.resolve('Georgia'), 'Georgia');
      expect(catalog.resolve('Papyrus'), 'Papyrus');
    });

    test('lista as fontes usadas que este computador não tem', () {
      expect(
        catalog.missing([
          'Lora',
          'Papyrus',
          'papyrus',
          'Comic Neue',
          'serif',
          'Georgia',
        ]),
        ['Papyrus', 'Comic Neue'],
      );
      expect(catalog.missing(const []), isEmpty);
    });
  });

  group('lista de fontes do sistema', () {
    test('normaliza: ordena, tira repetidas, internas e alternativas', () {
      expect(
        normalizeFamilies([
          'Noto Sans,Noto Sans Regular',
          '.SF NS',
          'arial',
          'Arial',
          '  ',
          'Zapfino',
        ]),
        ['arial', 'Noto Sans', 'Zapfino'],
      );
    });

    test('lê o registro de fontes do Windows e tira estilo e formato', () {
      const output = r'''
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
    Arial (TrueType)    REG_SZ    arial.ttf
    Arial Bold (TrueType)    REG_SZ    arialbd.ttf
    Arial Bold Italic (TrueType)    REG_SZ    arialbi.ttf
    Cambria & Cambria Math (TrueType)    REG_SZ    cambria.ttc
    Segoe UI Semibold (TrueType)    REG_SZ    seguisb.ttf
''';
      expect(normalizeFamilies(parseWindowsFontRegistry(output)), [
        'Arial',
        'Cambria',
        'Segoe UI',
      ]);
    });
  });

  group('fontes do projeto', () {
    late Directory folder;
    late Directory outside;
    late StoryProject project;
    const repository = ProjectFontsRepository(ProjectFiles());

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('plotcraft-fonts-');
      outside = await Directory.systemTemp.createTemp('plotcraft-fonts-src-');
      final now = DateTime.utc(2026);
      project = StoryProject(
        id: 'pf1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder.path,
      );
      await File(p.join(folder.path, 'project.json'))
          .writeAsString('{"id":"pf1"}');
    });

    tearDown(() async {
      await folder.delete(recursive: true);
      await outside.delete(recursive: true);
    });

    Future<String> source(
      String name, {
      String from = 'Lora-Regular.ttf',
    }) async {
      final copy = File(p.join(outside.path, name));
      await File('assets/fonts/$from').copy(copy.path);
      return copy.path;
    }

    test('sem pasta não há fontes', () async {
      expect(await repository.list(project), isEmpty);
    });

    test(
      'adiciona fontes reais, copiando para fonts/ sem sobrescrever',
      () async {
        final a = await source('minha-lora.ttf');
        final first = await repository.add(project, [a]);
        final second = await repository.add(project, [a]);
        expect(first.single.family, 'Lora');
        expect(first.single.file, 'minha-lora.ttf');
        expect(second.single.file, 'minha-lora-2.ttf');
        expect(
          await File(p.join(folder.path, 'fonts', 'minha-lora.ttf')).exists(),
          isTrue,
        );
        expect((await repository.list(project)).map((f) => f.family), [
          'Lora',
          'Lora',
        ]);
      },
    );

    test(
      'ignora o que não é fonte, não existe ou tem extensão errada',
      () async {
        final text = File(p.join(outside.path, 'falsa.ttf'))
          ..writeAsStringSync('não sou uma fonte');
        final notFont = File(p.join(outside.path, 'nota.txt'))
          ..writeAsStringSync('x');
        final good = await source('boa.otf', from: 'Roboto-Regular.ttf');
        final added = await repository.add(project, [
          text.path,
          notFont.path,
          p.join(outside.path, 'sumiu.ttf'),
          good,
        ]);
        expect(added.map((f) => f.file), ['boa.otf']);
        expect(added.single.family, 'Roboto');
      },
    );

    test(
      'lista ignora arquivos estranhos dentro de fonts/ e ordena por família',
      () async {
        await repository.add(project, [
          await source('r.ttf', from: 'Roboto-Regular.ttf'),
          await source('l.ttf'),
        ]);
        File(p.join(folder.path, 'fonts', 'leia-me.txt'))
            .writeAsStringSync('oi');
        File(p.join(folder.path, 'fonts', 'quebrada.ttf'))
            .writeAsStringSync('xx');
        expect((await repository.list(project)).map((f) => f.family), [
          'Lora',
          'Roboto',
        ]);
      },
    );

    test('remove só pelo nome do arquivo, sem sair da pasta', () async {
      final added = await repository.add(project, [await source('l.ttf')]);
      await expectLater(
        repository.remove(project, '../project.json'),
        throwsFormatException,
      );
      expect(await File(p.join(folder.path, 'project.json')).exists(), isTrue);
      await repository.remove(project, added.single.file);
      expect(await repository.list(project), isEmpty);
    });

    test('a loja carrega as fontes e monta o catálogo', () async {
      final store = testFontsStore(['Georgia', 'Arial']);
      await repository.add(project, [await source('l.ttf')]);
      await store.load(project);
      expect(store.catalog.project, ['Lora']);
      expect(store.catalog.system, ['Georgia', 'Arial']);
      expect(store.catalog.projectKey, 'pf1');
      final extra = await source('r.ttf', from: 'Roboto-Regular.ttf');
      final added = await store.add(project, [extra]);
      expect(added, hasLength(1));
      expect(store.catalog.project, containsAll(['Lora', 'Roboto']));
      await store.remove(
        project,
        store.projectFonts.firstWhere((f) => f.family == 'Roboto'),
      );
      expect(store.catalog.project, ['Lora']);
    });
  });

  group('editor', () {
    Future<QuillController> pump(
      WidgetTester tester, {
      required List<Map<String, dynamic>> ops,
      EditorFontCatalog? fonts,
      VoidCallback? onManage,
    }) async {
      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = QuillController(
        document: Document.fromJson(ops),
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
              fonts:
                  fonts ??
                  const EditorFontCatalog(bundled: ['Lora'], projectKey: 'k'),
              onManageFonts: onManage,
              backend: _NoSpell(),
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

    testWidgets('fonte que o computador não tem mostra o aviso com a ação', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        ops: [
          {
            'insert': 'Texto',
            'attributes': {'font': 'Papyrus'},
          },
          {'insert': ' comum\n'},
        ],
        onManage: () => opened++,
      );
      expect(find.textContaining('editor.missing_fonts'), findsWidgets);
      await tester.tap(find.text('editor.missing_fonts_action'));
      expect(opened, 1);
      await finish(tester);
    });

    testWidgets('fontes conhecidas não geram aviso', (tester) async {
      await pump(
        tester,
        ops: [
          {
            'insert': 'Texto',
            'attributes': {'font': 'Lora'},
          },
          {'insert': '\n'},
        ],
      );
      expect(find.textContaining('editor.missing_fonts'), findsNothing);
      await finish(tester);
    });

    testWidgets('trocar a fonte para uma que existe tira o aviso', (
      tester,
    ) async {
      final controller = await pump(
        tester,
        ops: [
          {
            'insert': 'Texto',
            'attributes': {'font': 'Papyrus'},
          },
          {'insert': '\n'},
        ],
      );
      expect(find.textContaining('editor.missing_fonts'), findsWidgets);
      controller.formatText(0, 5, Attribute.fromKeyValue('font', 'Lora'));
      await tester.pump();
      expect(find.textContaining('editor.missing_fonts'), findsNothing);
      await finish(tester);
    });

    testWidgets(
      'texto com fonte do projeto é desenhado com o nome registrado',
      (tester) async {
        await pump(
          tester,
          ops: [
            {
              'insert': 'Elegante',
              'attributes': {'font': 'Garamond Premier'},
            },
            {'insert': '\n'},
          ],
          fonts: const EditorFontCatalog(
            bundled: ['Lora'],
            project: ['Garamond Premier'],
            projectKey: 'k1',
          ),
        );
        final families = <String?>[];
        for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
          rich.text.visitChildren((span) {
            if (span is TextSpan && span.text == 'Elegante') {
              families.add(span.style?.fontFamily);
            }
            return true;
          });
        }
        expect(families, ['project:k1:Garamond Premier']);
        await finish(tester);
      },
    );

    testWidgets('o botão de fontes só aparece quando há como gerenciá-las', (
      tester,
    ) async {
      await pump(
        tester,
        ops: [
          {'insert': 'a\n'},
        ],
      );
      expect(find.byTooltip('editor.fonts'), findsNothing);
      await finish(tester);
      await pump(
        tester,
        ops: [
          {'insert': 'a\n'},
        ],
        onManage: () {},
      );
      expect(find.byTooltip('editor.fonts'), findsOneWidget);
      await finish(tester);
    });
  });
}
