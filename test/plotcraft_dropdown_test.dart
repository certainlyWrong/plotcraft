import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_dropdown.dart';
import 'package:plotcraft/core/ui/plotcraft_text_field.dart';

void main() {
  testWidgets('o dropdown tem a mesma altura do campo de texto ao lado', (
    tester,
  ) async {
    Widget box(Widget child) => SizedBox(width: 300, child: child);
    const items = [DropdownMenuItem(value: 'a', child: Text('A'))];
    final field = TextEditingController(text: 'a');
    addTearDown(field.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: Scaffold(
          body: Column(
            children: [
              box(PlotcraftTextField(controller: field, label: 'Nome')),
              box(
                PlotcraftDropdown<String>(
                  initialValue: 'a',
                  items: items,
                  onChanged: (_) {},
                ),
              ),
              box(PlotcraftTextField(controller: field, compact: true)),
              box(
                PlotcraftDropdown<String>(
                  compact: true,
                  initialValue: 'a',
                  items: items,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final heights = [
      for (final decorator in tester.widgetList(find.byType(InputDecorator)))
        tester.getSize(find.byWidget(decorator)).height,
    ];
    expect(heights[1], heights[0]);
    expect(heights[3], heights[2]);
  });
}
