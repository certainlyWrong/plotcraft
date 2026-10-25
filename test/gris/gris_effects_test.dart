import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/gris/gris.dart';
import 'package:plotcraft/core/ui/gris/line_work.dart';

Widget _host(Widget child, {bool still = false}) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  ambientClockTests();
  group('com movimento', () {
    testWidgets('todos os efeitos desenham sem erro e animam', (tester) async {
      await tester.pumpWidget(
        _host(
          const Stack(
            children: [
              SizedBox(width: 400, height: 300, child: WatercolorWash()),
              SizedBox(width: 400, height: 300, child: PaperGrain()),
              OrbitRings(size: 300),
              Constellation(),
              SizedBox(width: 600, child: ArchBridge()),
              InkStroke(),
              Reveal(child: Text('olá')),
              MorphBadge(child: Icon(Icons.circle)),
            ],
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('olá'), findsOneWidget);
      // Let every controller finish before the test ends.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('Reveal termina visível e sem filtro', (tester) async {
      await tester.pumpWidget(_host(const Reveal(child: Text('texto'))));
      expect(
        tester.widget<Opacity>(find.byType(Opacity).first).opacity,
        lessThan(.2),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('Reveal respeita o atraso', (tester) async {
      await tester.pumpWidget(
        _host(
          const Reveal(
            delay: Duration(milliseconds: 500),
            child: Text('texto'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('movimento reduzido', () {
    testWidgets('nada anima: o quadro assenta de imediato', (tester) async {
      await tester.pumpWidget(
        _host(
          const Stack(
            children: [
              SizedBox(width: 400, height: 300, child: WatercolorWash()),
              OrbitRings(size: 300),
              Constellation(),
              SizedBox(width: 600, child: ArchBridge()),
              InkStroke(),
              Reveal(child: Text('olá')),
              MorphBadge(child: Icon(Icons.circle)),
            ],
          ),
          still: true,
        ),
      );
      // pumpAndSettle would time out if any ticker kept running.
      await tester.pumpAndSettle();
      expect(find.text('olá'), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('PigmentDrop', () {
    testWidgets('floresce ao passar o mouse e some ao sair', (tester) async {
      await tester.pumpWidget(
        _host(const PigmentDrop(child: SizedBox(width: 80, height: 30))),
      );
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(SizedBox).last));
      await tester.pump();
      expect(opacity(), greaterThan(0));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(opacity(), 0);
      await tester.pumpAndSettle();
    });
  });

  group('LineWork', () {
    test('partial desenha só a fração pedida', () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      double length(Path p) =>
          p.computeMetrics().fold(0.0, (sum, m) => sum + m.length);
      expect(length(LineWork.partial(line, 0)), 0);
      expect(length(LineWork.partial(line, .25)), closeTo(25, .01));
      expect(length(LineWork.partial(line, 1)), closeTo(100, .01));
    });

    test('dashed alterna traço e vazio', () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = LineWork.dashed(line, const [10, 10]);
      final lengths = dashed.computeMetrics().map((m) => m.length).toList();
      expect(lengths, hasLength(5));
      expect(lengths.every((l) => (l - 10).abs() < .01), isTrue);
    });

    test('staggered respeita a ordem e termina em 1', () {
      const step = Duration(milliseconds: 100);
      const each = Duration(milliseconds: 400);
      final total = LineWork.totalFor(3, step, each);
      double at(double t, int i) =>
          LineWork.staggered(t, index: i, step: step, each: each, total: total);
      expect(at(0, 0), 0);
      expect(at(.3, 0), greaterThan(at(.3, 2)));
      expect(at(1, 2), 1);
    });
  });

  group('MorphBadge', () {
    test('começa e termina quadrado, passa por círculo e folha', () {
      expect(MorphBadge.cornersAt(0), [.25, .25, .25, .25]);
      expect(MorphBadge.cornersAt(1), [.25, .25, .25, .25]);
      expect(MorphBadge.cornersAt(.35), everyElement(closeTo(.5, 1e-9)));
      final leaf = MorphBadge.cornersAt(.70);
      expect(leaf[0], closeTo(.5, 1e-9));
      expect(leaf[1], closeTo(.25, 1e-9));
    });
  });

  test('estágios: tinta clareia no escuro e escurece no claro', () {
    for (final id in StageId.values) {
      expect(
        GrisStages.dark[id]!.ink.computeLuminance(),
        greaterThan(GrisStages.dark[id]!.pigment.computeLuminance()),
        reason: '$id escuro',
      );
      expect(
        GrisStages.light[id]!.ink.computeLuminance(),
        lessThan(GrisStages.light[id]!.pigment.computeLuminance()),
        reason: '$id claro',
      );
    }
  });
}

void ambientClockTests() {
  group('GrisClock', () {
    Widget host(Widget child, {bool tickers = true}) => MaterialApp(
      home: TickerMode(enabled: tickers, child: child),
    );

    testWidgets('avança com o tempo', (tester) async {
      late ValueListenable<double> seconds;
      await tester.pumpWidget(
        host(
          GrisClock(
            builder: (context, s) {
              seconds = s;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(seconds.value, greaterThan(1));
    });

    testWidgets('para quando o widget está oculto (TickerMode desligado)', (
      tester,
    ) async {
      late ValueListenable<double> seconds;
      await tester.pumpWidget(
        host(
          tickers: false,
          GrisClock(
            builder: (context, s) {
              seconds = s;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(seconds.value, 0);
    });

    testWidgets('congela no deslocamento com movimento reduzido', (
      tester,
    ) async {
      late ValueListenable<double> seconds;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: GrisClock(
              offset: 5,
              builder: (context, s) {
                seconds = s;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(seconds.value, 5);
    });
  });
}
