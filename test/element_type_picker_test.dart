import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_type_picker.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    void Function(String?) onResult, {
    bool allowCreate = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onResult(
              await showElementTypePicker(
                context,
                ElementTypeCatalog.builtin,
                allowCreate: allowCreate,
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra um cartão por tipo e devolve o ID escolhido', (
    tester,
  ) async {
    String? chosen;
    await open(tester, (id) => chosen = id);
    for (final type in ElementTypeCatalog.builtin) {
      expect(find.text(type.nameKey!), findsOneWidget);
    }
    expect(find.text('elements.new_type'), findsNothing);
    await tester.tap(find.text('elements.types.creature'));
    await tester.pumpAndSettle();
    expect(chosen, 'creature');
  });

  testWidgets('o cartão de novo tipo só aparece quando permitido', (
    tester,
  ) async {
    String? chosen;
    await open(tester, (id) => chosen = id, allowCreate: true);
    await tester.tap(find.text('elements.new_type'));
    await tester.pumpAndSettle();
    expect(chosen, createElementTypeChoice);
  });

  testWidgets('cancelar devolve null', (tester) async {
    String? chosen = 'x';
    await open(tester, (id) => chosen = id);
    await tester.tap(find.text('preferences.cancel'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });
}
