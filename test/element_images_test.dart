import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/gallery_item.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_editor.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_images_panel.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/gallery_picker_dialog.dart';
import 'package:plotcraft/features/project_workspace/stores/project_workspace_store.dart';
import 'package:plotcraft/features/project_workspace/stores/workspace_controller.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'support/fake_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('painel: capa marcada, ausentes sinalizadas e ações disparam', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _app(
        ElementImagesPanel(
          images: const [
            ElementImage.gallery('g1'),
            ElementImage.gallery('g2'),
            ElementImage.attachment('content/narrative/attachments/e/x.png'),
          ],
          resolvePath: (image) =>
              image.value == 'g2' ? null : '/nao/existe.png',
          onAddFromGallery: () => events.add('gallery'),
          onAddFromComputer: () => events.add('computer'),
          onRemove: (i) => events.add('remove$i'),
          onMakeCover: (i) => events.add('cover$i'),
        ),
      ),
    );
    expect(find.text('elements.cover'), findsOneWidget);
    expect(find.byTooltip('elements.image_missing'), findsOneWidget);
    // Only images after the first can become the cover.
    expect(find.byTooltip('elements.set_cover'), findsNWidgets(2));

    await tester.tap(find.text('elements.add_from_gallery'));
    await tester.tap(find.text('elements.add_from_computer'));
    await tester.tap(find.byTooltip('elements.set_cover').last);
    await tester.tap(find.byTooltip('elements.remove').first);
    expect(events, ['gallery', 'computer', 'cover2', 'remove0']);
  });

  testWidgets('painel vazio mostra a dica', (tester) async {
    await tester.pumpWidget(
      _app(
        ElementImagesPanel(
          images: const [],
          resolvePath: (_) => null,
          onAddFromGallery: () {},
          onAddFromComputer: () {},
          onRemove: (_) {},
          onMakeCover: (_) {},
        ),
      ),
    );
    expect(find.text('elements.no_images'), findsOneWidget);
  });

  testWidgets('o seletor da galeria mantém as já usadas e devolve a seleção', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    List<String>? result;
    const items = [
      GalleryItem(id: 'a', file: 'a.png', path: '/x/a.png', exists: true),
      GalleryItem(id: 'b', file: 'b.png', path: '/x/b.png', exists: true),
      GalleryItem(id: 'c', file: 'c.png', path: '/x/c.png', exists: false),
    ];
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showGalleryPicker(
              context,
              items: items,
              selected: const ['a'],
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    // The missing file is not offered.
    final tiles = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(InkWell),
    );
    expect(tiles, findsNWidgets(2));
    await tester.tap(tiles.last);
    await tester.pump();
    await tester.tap(find.text('ui.save'));
    await tester.pumpAndSettle();
    expect(result, unorderedEquals(['a', 'b']));
  });

  testWidgets(
    'no editor, imagens da galeria escolhidas são salvas no elemento',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final folder = await tester.runAsync(
        () => Directory.systemTemp.createTemp('plotcraft-el-img-'),
      );
      addTearDown(() => folder!.delete(recursive: true));
      final now = DateTime.utc(2026);
      final project = StoryProject(
        id: 'im1',
        title: 'Livro',
        description: '',
        createdAt: now,
        updatedAt: now,
        coverIndex: 0,
        directoryPath: folder!.path,
      );
      final store = ProjectWorkspaceStore(ProjectWorkspaceRepository(), (_) {});
      final controller = WorkspaceController(
        store,
        project,
        null,
        testFontsStore(),
      );
      addTearDown(controller.dispose);
      await tester.runAsync(() async {
        await File(p.join(folder.path, 'project.json'))
            .writeAsString('{"id":"im1"}');
        await File(p.join(folder.path, 'gallery', 'foto.png'))
            .create(recursive: true)
            .then((f) => f.writeAsBytes([1, 2, 3]));
        await store.load(project);
      });
      final tabId = controller.newElementDraft('character');
      await tester.pumpWidget(
        _app(
          ElementEditor(
            tab: controller.tabs.firstWhere((t) => t.id == tabId),
            store: store,
            controller: controller,
            book: store.book,
            onRemove: (_) {},
            onOpenReference: (_, _) {},
            onOpenElement: (_) {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.tap(find.text('elements.add_from_gallery'));
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
      await tester.tap(find.text('ui.save').last);
      await tester.pumpAndSettle();
      expect(find.text('elements.cover'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('workspace.save_project').first);
        for (var i = 0; i < 200 && store.elements.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      final saved = store.elements.single;
      expect(saved.images.single.isGallery, isTrue);
      expect(saved.images.single.value, store.galleryItems.single.id);
    },
  );
}
