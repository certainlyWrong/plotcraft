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
    await tester.tap(find.text('Feather'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'activity');
    await tester.pump();
    expect(find.byIcon(Feather.activity), findsOneWidget);
    await tester.tap(find.byIcon(Feather.activity));
    expect(picked, const IconRef('Feather', 'activity'));

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pump();
    expect(find.text('ui.icon_picker_empty'), findsOneWidget);
  });

  testWidgets('o seletor abre nos ícones sugeridos e a busca os filtra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    IconRef? picked;
    await tester.pumpWidget(
      _app(PlotcraftIconPicker(onSelected: (ref) => picked = ref)),
    );
    // Starts on the suggestions: groups with their titles.
    expect(find.text('UI.ICON_GROUPS.PEOPLE'), findsOneWidget);
    expect(find.byIcon(RpgAwesome.dragon), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dragon');
    await tester.pump();
    expect(find.byIcon(RpgAwesome.dragon), findsOneWidget);
    expect(find.text('UI.ICON_GROUPS.PEOPLE'), findsNothing);
    await tester.tap(find.byIcon(RpgAwesome.dragon));
    expect(picked, const IconRef('RpgAwesome', 'dragon'));
  });

  testWidgets('um ícone atual fora das sugestões abre no próprio conjunto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PlotcraftIconPicker(
          current: const IconRef('Feather', 'activity'),
          onSelected: (_) {},
        ),
      ),
    );
    expect(find.byIcon(Feather.activity), findsOneWidget);
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
