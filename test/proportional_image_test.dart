import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/ui/proportional_image.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/element_hover_card.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

void main() {
  tearDown(() {
    for (final path in ['larga', 'alta', 'extrema', 'nova']) {
      ImageAspects.forget(path);
    }
  });

  Future<void> pump(WidgetTester tester, Widget child, {double width = 300}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      );

  Finder box(String path) => find.descendant(
    of: find.byType(ProportionalImage),
    matching: find.byType(AspectRatio),
  );

  testWidgets('a caixa segue a proporção real e a imagem a preenche', (
    tester,
  ) async {
    await pump(tester, ProportionalImage('larga', readAspect: (_) async => 2));
    await tester.pump();
    expect(tester.getSize(box('larga')), const Size(300, 150));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
  });

  testWidgets('imagem alta é limitada, preenche e mantém o topo', (
    tester,
  ) async {
    await pump(
      tester,
      ProportionalImage('extrema', minAspect: .75, readAspect: (_) async => .2),
    );
    await tester.pump();
    expect(tester.getSize(box('extrema')).aspectRatio, closeTo(.75, .01));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.topCenter);
  });

  testWidgets('usa a forma provisória até ler e se ilegível', (tester) async {
    await pump(
      tester,
      ProportionalImage(
        'nova',
        loadingAspect: 1,
        readAspect: (_) async => throw StateError('ilegível'),
      ),
    );
    expect(tester.getSize(box('nova')), const Size(300, 300));
    await tester.pump();
    expect(tester.getSize(box('nova')), const Size(300, 300));
  });

  testWidgets('reaproveita a proporção já lida desde o primeiro quadro', (
    tester,
  ) async {
    await pump(tester, ProportionalImage('alta', readAspect: (_) async => .5));
    await tester.pump();
    await pump(tester, const SizedBox());
    await pump(
      tester,
      ProportionalImage(
        'alta',
        readAspect: (_) async => throw StateError('não devia ler de novo'),
      ),
    );
    expect(tester.getSize(box('alta')), const Size(300, 600));
  });

  testWidgets('o cartão da menção respeita a proporção da capa', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('plotcraft-card-');
    addTearDown(() => folder.deleteSync(recursive: true));
    final path = '${folder.path}/capa.png';
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 600, 200),
        Paint()..color = const Color(0xFF3366CC),
      );
      final image = await recorder.endRecording().toImage(600, 200);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(data!.buffer.asUint8List());
      ImageAspects.forget(path);
      await ImageAspects.of(path);
    });
    addTearDown(() => ImageAspects.forget(path));
    final element = NarrativeElement(
      id: 'lia',
      typeId: 'character',
      title: 'Lia',
      summary: '',
      sections: const [],
      phases: const [],
      fields: const {},
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ElementHoverCard(
              element: element,
              type: ElementTypeCatalog.resolve('character', const []),
              coverPath: path,
              phase: null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // 600 x 200 is 3:1, so a 320 wide card has a cover 107 high.
    expect(
      tester.getSize(find.byType(AspectRatio)),
      Size(ElementHoverCard.width, ElementHoverCard.width / 3),
    );
  });
}
