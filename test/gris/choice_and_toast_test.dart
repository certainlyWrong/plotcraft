import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_chip.dart';
import 'package:plotcraft/core/ui/plotcraft_choice.dart';
import 'package:plotcraft/core/ui/plotcraft_toast.dart';

Widget _app(Widget child, {StageId stage = StageId.blue}) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true, size: Size(1000, 700)),
    child: StageScope(
      stage: stage,
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  group('PlotcraftChoice', () {
    Widget choice(ValueChanged<String> onChanged, {String selected = 'a'}) =>
        PlotcraftChoice<String>(
          options: const [
            PlotcraftChoiceOption(value: 'a', label: 'Auto'),
            PlotcraftChoiceOption(value: 'b', label: 'Sempre'),
            PlotcraftChoiceOption(value: 'c', label: 'Nunca', icon: Icons.add),
          ],
          selected: selected,
          onChanged: onChanged,
        );

    testWidgets('mostra todas as opções e marca só a escolhida', (
      tester,
    ) async {
      await tester.pumpWidget(_app(choice((_) {}, selected: 'b')));
      final chips = tester
          .widgetList<PlotcraftChip>(find.byType(PlotcraftChip))
          .toList();
      expect(chips.map((c) => c.label), ['Auto', 'Sempre', 'Nunca']);
      expect(chips.map((c) => c.selected), [false, true, false]);
    });

    testWidgets('tocar escolhe a opção', (tester) async {
      String? picked;
      await tester.pumpWidget(_app(choice((v) => picked = v)));
      await tester.tap(find.text('Nunca'));
      expect(picked, 'c');
    });

    testWidgets('quebra a linha num painel estreito em vez de estourar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SizedBox(width: 120, child: choice((_) {}))),
      );
      expect(tester.takeException(), isNull);
      // All three still on screen, on more than one row.
      final tops = {
        for (final label in ['Auto', 'Sempre', 'Nunca'])
          tester.getTopLeft(find.text(label)).dy,
      };
      expect(tops.length, greaterThan(1));
    });
  });

  group('PlotcraftToaster', () {
    testWidgets('mostra a mensagem com a pinta de tinta do estágio', (
      tester,
    ) async {
      late PlotcraftToaster toaster;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              toaster = PlotcraftToaster.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      toaster.show('Salvo.');
      await tester.pump();
      expect(find.text('Salvo.'), findsOneWidget);
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle,
          ),
        ),
      );
      expect(
        (dot.decoration! as BoxDecoration).color,
        GrisStages.dark[StageId.blue]!.ink,
      );
    });

    testWidgets('uma nova mensagem substitui a anterior', (tester) async {
      late PlotcraftToaster toaster;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              toaster = PlotcraftToaster.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      toaster
        ..show('Trabalhando…', duration: const Duration(seconds: 30))
        ..show('Pronto');
      await tester.pumpAndSettle();
      expect(find.text('Pronto'), findsOneWidget);
      expect(find.text('Trabalhando…'), findsNothing);
    });

    testWidgets('funciona depois que a tela que o criou saiu da árvore', (
      tester,
    ) async {
      late PlotcraftToaster toaster;
      final show = ValueNotifier(true);
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<bool>(
            valueListenable: show,
            builder: (context, on, _) {
              if (on) toaster = PlotcraftToaster.of(context);
              return on ? const Text('tela') : const SizedBox();
            },
          ),
        ),
      );
      show.value = false;
      await tester.pump();
      // The creating widget is gone, yet the toast must not touch its context.
      expect(() => toaster.show('Depois do await'), returnsNormally);
      await tester.pump();
      expect(find.text('Depois do await'), findsOneWidget);
    });

    testWidgets('plotcraftToast devolve um SnackBar pronto', (tester) async {
      late SnackBar bar;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              bar = plotcraftToast(context, 'Oi');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(bar.behavior, SnackBarBehavior.floating);
    });
  });
}
