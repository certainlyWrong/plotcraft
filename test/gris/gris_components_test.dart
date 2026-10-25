import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/gris/gris.dart';
import 'package:plotcraft/core/ui/plotcraft_button.dart';
import 'package:plotcraft/core/ui/plotcraft_chip.dart';
import 'package:plotcraft/core/ui/plotcraft_dialog.dart';
import 'package:plotcraft/core/ui/plotcraft_segmented.dart';
import 'package:plotcraft/core/ui/plotcraft_surface.dart';
import 'package:plotcraft/core/ui/plotcraft_tab_bar.dart';

Widget _app(Widget child, {StageId stage = StageId.red}) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: StageScope(
      stage: stage,
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  group('PlotcraftButton', () {
    testWidgets(
      'o primário usa a tinta do estágio e floresce ao passar o mouse',
      (tester) async {
        await tester.pumpWidget(
          _app(PlotcraftButton(label: 'Salvar', onPressed: () {})),
        );
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(
          button.style!.backgroundColor!.resolve({}),
          GrisStages.dark[StageId.red]!.ink,
        );
        expect(find.byType(PigmentDrop), findsOneWidget);
      },
    );

    testWidgets('trocar de estágio troca a cor do botão', (tester) async {
      Widget build(StageId stage) => _app(
        PlotcraftButton(label: 'Salvar', onPressed: () {}),
        stage: stage,
      );
      await tester.pumpWidget(build(StageId.red));
      await tester.pumpWidget(build(StageId.blue));
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style!.backgroundColor!.resolve({}),
        GrisStages.dark[StageId.blue]!.ink,
      );
    });

    testWidgets('desabilitado não floresce', (tester) async {
      await tester.pumpWidget(
        _app(const PlotcraftButton(label: 'Salvar', onPressed: null)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });
  });

  group('PlotcraftChip', () {
    testWidgets('toca para escolher e remove pelo x', (tester) async {
      var taps = 0;
      var removed = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlotcraftChip(label: 'Um', onTap: () => taps++),
              PlotcraftChip(label: 'Dois', onDeleted: () => removed++),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Um'));
      await tester.tap(find.byIcon(Feather.x));
      expect((taps, removed), (1, 1));
    });

    testWidgets('o selecionado se anuncia como selecionado', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(PlotcraftChip(label: 'Um', selected: true, onTap: () {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Um')),
        isSemantics(label: 'Um', isSelected: true, isButton: true),
      );
      handle.dispose();
    });
  });

  group('PlotcraftSurface', () {
    testWidgets('só reage ao toque quando recebe onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PlotcraftSurface(child: Text('quieta')),
              PlotcraftSurface(onTap: () => taps++, child: const Text('viva')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('quieta'));
      await tester.tap(find.text('viva'));
      expect(taps, 1);
    });
  });

  group('PlotcraftSegmented', () {
    testWidgets('a marca desliza até a opção escolhida', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => PlotcraftSegmented<int>(
              segments: const [
                PlotcraftSegment(value: 0, icon: Icons.edit, tooltip: 'A'),
                PlotcraftSegment(value: 1, icon: Icons.add, tooltip: 'B'),
              ],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );
      double left() => tester
          .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
          .left!;
      expect(left(), 0);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(left(), 34);
    });
  });

  group('PlotcraftDialog', () {
    testWidgets('mostra título, pincelada, conteúdo e ações', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PlotcraftDialog(
                  title: 'Título',
                  content: const Text('Corpo'),
                  actions: [PlotcraftButton(label: 'Ok', onPressed: () {})],
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Título'), findsOneWidget);
      expect(find.byType(InkStroke), findsOneWidget);
      expect(find.text('Corpo'), findsOneWidget);
      expect(find.text('Ok'), findsOneWidget);
    });
  });

  group('PlotcraftTabBar', () {
    testWidgets('a aba aberta tem a linha de tinta embaixo', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 500,
            child: PlotcraftTabBar(
              tabs: const [
                PlotcraftTabData(id: 'a', title: 'A', icon: Icons.circle),
                PlotcraftTabData(id: 'b', title: 'B', icon: Icons.circle),
              ],
              activeId: 'a',
              onSelect: (_) {},
              onClose: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ink = GrisStages.dark[StageId.red]!.ink;
      Color? underline(String title) {
        final container = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return ((container.decoration! as BoxDecoration).border! as Border)
            .bottom
            .color;
      }

      expect(underline('A'), ink);
      expect(underline('B'), Colors.transparent);
    });
  });
}
