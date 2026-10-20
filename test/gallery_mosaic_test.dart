import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/proportional_image.dart';
import 'package:plotcraft/features/project_workspace/presentation/widgets/gallery_mosaic.dart';

Future<void> _png(String path, int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  group('readImageAspect', () {
    late Directory folder;

    setUp(
      () => folder = Directory.systemTemp.createTempSync('plotcraft-mosaic-'),
    );
    tearDown(() => folder.deleteSync(recursive: true));

    testWidgets('lê a proporção real do arquivo', (tester) async {
      await tester.runAsync(() async {
        await _png('${folder.path}/larga.png', 400, 200);
        await _png('${folder.path}/alta.png', 150, 600);
        expect(await readImageAspect('${folder.path}/larga.png'), 2.0);
        expect(await readImageAspect('${folder.path}/alta.png'), .25);
      });
    });

    testWidgets('falha com arquivo que não é imagem', (tester) async {
      await tester.runAsync(() async {
        File('${folder.path}/x.png').writeAsStringSync('não é imagem');
        await expectLater(
          readImageAspect('${folder.path}/x.png'),
          throwsA(anything),
        );
      });
    });
  });

  group('GalleryMosaic', () {
    Future<void> pumpMosaic(
      WidgetTester tester,
      Map<String, double> aspects,
    ) async {
      tester.view.physicalSize = const Size(1300, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: GalleryMosaic(
              images: aspects.keys.toList(),
              removingImage: false,
              importing: false,
              aspectOf: (path) async =>
                  aspects[path] ?? (throw StateError('sem proporção')),
              onSelect: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder tile(String path) => find.byKey(ValueKey(path));

    testWidgets('cada imagem mantém a proporção real, sem corte', (
      tester,
    ) async {
      await pumpMosaic(tester, {'larga': 2.0, 'alta': .5, 'quadrada': 1.0});
      expect(tester.getSize(tile('larga')).aspectRatio, closeTo(2.0, .01));
      expect(tester.getSize(tile('alta')).aspectRatio, closeTo(.5, .01));
      expect(tester.getSize(tile('quadrada')).aspectRatio, closeTo(1.0, .01));
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images.every((image) => image.fit == BoxFit.cover), isTrue);
    });

    testWidgets('formas extremas ficam limitadas e preenchem o quadro', (
      tester,
    ) async {
      await pumpMosaic(tester, {'panorama': 10.0, 'torre': .1});
      expect(
        tester.getSize(tile('panorama')).aspectRatio,
        closeTo(GalleryMosaic.maxAspect, .01),
      );
      expect(
        tester.getSize(tile('torre')).aspectRatio,
        closeTo(GalleryMosaic.minAspect, .01),
      );
      // The tall one keeps its top, the wide one stays centered.
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.map((i) => i.alignment), [
        Alignment.center,
        Alignment.topCenter,
      ]);
    });

    testWidgets('arquivo ilegível usa a proporção padrão', (tester) async {
      await pumpMosaic(tester, {'ok': 2.0});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GalleryMosaic(
              images: const ['quebrada'],
              removingImage: false,
              importing: false,
              aspectOf: (_) async => throw StateError('quebrada'),
              onSelect: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(tile('quebrada')).aspectRatio,
        closeTo(GalleryMosaic.placeholderAspect, .01),
      );
    });

    testWidgets('coloca cada imagem na coluna mais curta', (tester) async {
      await pumpMosaic(tester, {
        'a': .5,
        'b': 2.0,
        'c': 2.0,
        'd': 2.0,
        'e': 2.0,
      });
      final lefts = {
        for (final path in ['a', 'b', 'c', 'd', 'e'])
          path: tester.getTopLeft(tile(path)).dx,
      };
      expect(lefts['a']!, lessThan(lefts['b']!));
      expect(lefts['b']!, lessThan(lefts['c']!));
      expect(lefts['c']!, lessThan(lefts['d']!));
      // Four columns: e goes under b (the first shortest), not under the tall a.
      expect(lefts['e'], lefts['b']);
    });
  });
}
