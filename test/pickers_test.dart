import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft/core/icons/icon_ref.dart';
import 'package:plotcraft/core/theme/color_hex.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_color_picker.dart';
import 'package:plotcraft/core/ui/plotcraft_icon_picker.dart';

Widget _app(Widget child) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: Scaffold(body: child),
);

void main() {
  test('cores: hex de ida e volta e entradas inválidas', () {
    expect(colorToHex(const Color(0xFF7B5EA7)), '#7B5EA7');
    expect(parseHexColor('#7b5ea7'), const Color(0xFF7B5EA7));
    expect(parseHexColor('7B5EA7'), const Color(0xFF7B5EA7));
    expect(parseHexColor('#7B5E'), isNull);
    expect(parseHexColor('xyz123'), isNull);
    expect(parseHexColor(null), isNull);
  });

  testWidgets('o seletor de ícones filtra pela busca e devolve a escolha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    IconRef? picked;
    await tester.pumpWidget(
      _app(PlotcraftIconPicker(onSelected: (ref) => picked = ref)),
    );
    await tester.enterText(find.byType(TextField), 'activity');
    await tester.pump();
    expect(find.byIcon(Feather.activity), findsOneWidget);
    await tester.tap(find.byIcon(Feather.activity));
    expect(picked, const IconRef('Feather', 'activity'));

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pump();
    expect(find.text('ui.icon_picker_empty'), findsOneWidget);
  });

  testWidgets('o seletor de ícones troca de conjunto', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    IconRef? picked;
    await tester.pumpWidget(
      _app(PlotcraftIconPicker(onSelected: (ref) => picked = ref)),
    );
    await tester.tap(find.text('RPG'));
    await tester.pump();
    await tester.tap(
      find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .first,
    );
    expect(picked?.set, 'RpgAwesome');
    expect(
      picked,
      IconRef('RpgAwesome', IconCatalog.namesIn('RpgAwesome').first),
    );
  });

  testWidgets('o seletor de cores aceita swatch e hexadecimal', (tester) async {
    Color? chosen;
    await tester.pumpWidget(
      _app(
        PlotcraftColorPicker(
          color: plotcraftSwatches.first,
          onChanged: (color) => chosen = color,
        ),
      ),
    );
    await tester.tap(find.byType(InkWell).at(3));
    expect(chosen, plotcraftSwatches[3]);
    await tester.enterText(find.byType(TextField), '#112233');
    expect(chosen, const Color(0xFF112233));
    chosen = null;
    await tester.enterText(find.byType(TextField), '#11');
    expect(chosen, isNull);
  });
}
