import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_chip.dart';
import 'package:plotcraft/core/ui/plotcraft_surface.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_section_card.dart';
import 'package:plotcraft/features/project_workspace/presentation/widgets/project_tags.dart';

Widget _app(Widget child, {StageId stage = StageId.green}) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: StageScope(
      stage: stage,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  group('folhas de papel', () {
    // A list tile paints its states on the Material beneath it; the sheet's
    // painted decoration must not sit between the two (it hid them, and in a
    // debug build it asserts).
    testWidgets('ListTile dentro de PlotcraftSurface não dispara o aviso', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          PlotcraftSurface(
            child: ListTile(title: const Text('linha'), onTap: () => taps++),
          ),
        ),
      );
      await tester.tap(find.text('linha'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SwitchListTile dentro de ElementSectionCard funciona', (
      tester,
    ) async {
      var on = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => ElementSectionCard(
              child: SwitchListTile(
                title: const Text('automático'),
                value: on,
                onChanged: (v) => setState(() => on = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(on, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PlotcraftCard deixa o conteúdo com o próprio espaçamento', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const PlotcraftCard(
            child: Padding(padding: EdgeInsets.all(20), child: Text('dentro')),
          ),
        ),
      );
      final card = tester.getRect(find.byType(PlotcraftCard));
      final text = tester.getRect(find.text('dentro'));
      expect(text.left - card.left, closeTo(21, 1)); // 20 + 1px edge
    });
  });

  group('ProjectTags', () {
    testWidgets('mostra uma etiqueta por palavra-chave', (tester) async {
      await tester.pumpWidget(
        _app(const ProjectTags(tags: ['magia', 'dívida', 'mar'])),
      );
      expect(find.byType(PlotcraftChip), findsNWidgets(3));
      expect(find.text('dívida'), findsOneWidget);
    });

    testWidgets('sem etiquetas não mostra nada', (tester) async {
      await tester.pumpWidget(_app(const ProjectTags(tags: [])));
      expect(find.byType(PlotcraftChip), findsNothing);
    });
  });

  group('PlotcraftChip com ícone', () {
    testWidgets('o ícone usa a cor própria, e a tinta do estágio por padrão', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              PlotcraftChip(label: 'A', icon: Icons.circle),
              PlotcraftChip(
                label: 'B',
                icon: Icons.square,
                iconColor: Color(0xFF123456),
              ),
            ],
          ),
        ),
      );
      Color? colorOf(IconData icon) =>
          tester.widget<Icon>(find.byIcon(icon)).color;
      expect(colorOf(Icons.circle), GrisStages.dark[StageId.green]!.ink);
      expect(colorOf(Icons.square), const Color(0xFF123456));
    });
  });
}
