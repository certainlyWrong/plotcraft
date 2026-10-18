import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/plotcraft_button.dart';
import 'package:plotcraft/core/ui/plotcraft_dialog.dart';
import 'package:plotcraft/core/ui/plotcraft_segmented.dart';
import 'package:plotcraft/core/ui/plotcraft_text_field.dart';

Widget _app(Widget home) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: Scaffold(body: home),
);

void main() {
  testWidgets(
    'showConfirmDialog devolve true ao confirmar e false ao cancelar',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showConfirmDialog(
                context,
                title: 'Título',
                message: 'Mensagem',
                confirmLabel: 'Remover',
                destructive: true,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Título'), findsOneWidget);
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('preferences.cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );

  testWidgets('diálogo com campo expansível monta sem erros de layout', (
    tester,
  ) async {
    final title = TextEditingController();
    final body = TextEditingController();
    addTearDown(title.dispose);
    addTearDown(body.dispose);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PlotcraftDialog(
                title: 'Seção',
                maxWidth: 740,
                content: SizedBox(
                  width: 740,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlotcraftTextField(controller: title, label: 'Título'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: PlotcraftTextField(
                          controller: body,
                          label: 'Texto',
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: const [],
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField).last, 'olá');
    expect(body.text, 'olá');
  });

  testWidgets('PlotcraftSegmented notifica a opção escolhida', (tester) async {
    var selected = 'a';
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => PlotcraftSegmented<String>(
            segments: const [
              PlotcraftSegment(value: 'a', icon: Icons.edit, tooltip: 'A'),
              PlotcraftSegment(
                value: 'b',
                icon: Icons.visibility,
                tooltip: 'B',
              ),
            ],
            selected: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(selected, 'b');
  });

  testWidgets('variante destrutiva do botão usa a cor de erro', (tester) async {
    await tester.pumpWidget(
      _app(
        PlotcraftButton(
          label: 'Excluir',
          variant: PlotcraftButtonVariant.destructive,
          onPressed: () {},
        ),
      ),
    );
    final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
    final scheme = Theme.of(tester.element(find.byType(TextButton)))
        .colorScheme;
    expect(style.foregroundColor!.resolve({}), scheme.error);
  });
}
