import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

/// [top] laid over [bottom] at [alpha].
Color _over(Color top, Color bottom, double alpha) =>
    Color.alphaBlend(top.withValues(alpha: alpha), bottom);

void main() {
  test('o cálculo de contraste bate com valores conhecidos do WCAG', () {
    expect(_ratio(Colors.black, Colors.white), closeTo(21, .01));
    expect(_ratio(Colors.white, Colors.white), closeTo(1, .001));
    // #767676 on white is the classic "just passes" grey (4.54:1)...
    expect(_ratio(const Color(0xFF767676), Colors.white), closeTo(4.54, .02));
    // ...and #777777 is just below it.
    expect(_ratio(const Color(0xFF8A8A8A), Colors.white), lessThan(4.5));
  });

  for (final theme in builtInThemes) {
    final stages = theme.isDark ? GrisStages.dark : GrisStages.light;
    final data = theme.toThemeData(fontFamily: 'Lora');
    final scheme = data.colorScheme;
    // The surfaces text sits on: the page, a panel, a raised sheet.
    final grounds = {
      'fundo': scheme.surfaceContainerLowest,
      'painel': scheme.surfaceContainer,
      'folha': scheme.surfaceContainerHigh,
    };

    group(theme.name, () {
      test('o texto comum tem contraste AA (4.5:1) nos fundos', () {
        grounds.forEach((name, ground) {
          expect(
            _ratio(scheme.onSurface, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'onSurface sobre $name',
          );
          expect(
            _ratio(scheme.onSurfaceVariant, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'texto secundário sobre $name',
          );
        });
      });

      for (final id in StageId.values) {
        final stage = stages[id]!;

        test(
          '${id.name}: a tinta, usada em texto e ícones, passa AA nos fundos',
          () {
            grounds.forEach((name, ground) {
              expect(
                _ratio(stage.ink, ground),
                greaterThanOrEqualTo(4.5),
                reason: 'tinta ${id.name} sobre $name',
              );
            });
          },
        );

        test('${id.name}: o texto sobre o botão primário (fundo de tinta) '
            'passa AA', () {
          // Same rule as PlotcraftButton.
          final onInk = stage.ink.computeLuminance() > .38
              ? const Color(0xFF17201D)
              : Colors.white;
          expect(_ratio(onInk, stage.ink), greaterThanOrEqualTo(4.5));
        });

        test('${id.name}: o texto sobre uma etiqueta selecionada passa AA', () {
          // Selected chip and list row: ink at 20-22% over the paper.
          for (final ground in grounds.values) {
            final patch = _over(stage.ink, ground, .22);
            expect(
              _ratio(scheme.onSurface, patch),
              greaterThanOrEqualTo(4.5),
              reason: 'texto sobre mancha de ${id.name}',
            );
          }
        });
      }

      test('o texto continua legível sobre a aquarela, no pior caso', () {
        // Worst case: the wash's pigment fully covering the page behind text.
        final tokens = data.extension<PlotcraftTokens>()!;
        for (final id in StageId.values) {
          final wash = _over(
            stages[id]!.pigment,
            scheme.surfaceContainerLowest,
            tokens.washOpacity,
          );
          expect(
            _ratio(scheme.onSurface, wash),
            greaterThanOrEqualTo(4.5),
            reason: 'texto sobre aquarela ${id.name}',
          );
          expect(
            _ratio(scheme.onSurfaceVariant, wash),
            greaterThanOrEqualTo(4.5),
            reason: 'texto secundário sobre aquarela ${id.name}',
          );
          expect(
            _ratio(stages[id]!.ink, wash),
            greaterThanOrEqualTo(4.5),
            reason: 'tinta ${id.name} sobre a própria aquarela',
          );
        }
      });

      test('a cor de erro (tinta vermelha) é legível nos fundos', () {
        grounds.forEach((name, ground) {
          expect(
            _ratio(scheme.error, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'erro sobre $name',
          );
        });
      });
    });
  }

  group('tinta de cada estágio é distinguível da vizinha', () {
    // Colour is progress: stages must not blur into each other.
    for (final (name, stages) in [
      ('escuro', GrisStages.dark),
      ('claro', GrisStages.light),
    ]) {
      test(name, () {
        final inks = [for (final id in StageId.values) stages[id]!.ink];
        for (var i = 0; i < inks.length; i++) {
          for (var j = i + 1; j < inks.length; j++) {
            final a = HSLColor.fromColor(inks[i]);
            final b = HSLColor.fromColor(inks[j]);
            final hue = (a.hue - b.hue).abs();
            final apart = hue > 25 && hue < 335;
            // The grey stage differs by saturation, not by hue.
            final greyVsColour = (a.saturation - b.saturation).abs() > .12;
            expect(
              apart || greyVsColour,
              isTrue,
              reason: '${StageId.values[i].name} x ${StageId.values[j].name}',
            );
          }
        }
      });
    }
  });
}
