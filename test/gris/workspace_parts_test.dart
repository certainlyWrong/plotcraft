import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/gris/gris.dart';
import 'package:plotcraft/features/project_workspace/domain/workspace_tab.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/activity_bar.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/side_panel.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/side_panel_widgets.dart';
import 'package:plotcraft/features/project_workspace/presentation/shell/workspace_stage.dart';

Widget _app(Widget child, {StageId stage = StageId.red}) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true, size: Size(1200, 800)),
    child: StageScope(
      stage: stage,
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  group('estágios do workspace', () {
    test('cada seção tem o seu estágio', () {
      expect(stageForSection(WorkspaceSection.overview), StageId.grey);
      expect(stageForSection(WorkspaceSection.manuscript), StageId.red);
      expect(stageForSection(WorkspaceSection.elements), StageId.green);
      expect(stageForSection(WorkspaceSection.graph), StageId.blue);
      expect(stageForSection(WorkspaceSection.timeline), StageId.blue);
      expect(stageForSection(WorkspaceSection.gallery), StageId.yellow);
    });

    test('todas as seções estão cobertas', () {
      for (final section in WorkspaceSection.values) {
        expect(() => stageForSection(section), returnsNormally);
      }
    });

    test('a leitura é amarela, mesmo sendo do manuscrito', () {
      expect(stageForTab(WorkspaceTab.reading), StageId.yellow);
      expect(stageForTab(WorkspaceTab.chapter('c1')), StageId.red);
      expect(stageForTab(WorkspaceTab.element('x')), StageId.green);
      expect(stageForTab(WorkspaceTab.overview), StageId.grey);
    });
  });

  group('ActivityBar', () {
    testWidgets('seleciona seções, exporta e volta', (tester) async {
      final picked = <WorkspaceSection>[];
      var exported = 0;
      var back = 0;
      await tester.pumpWidget(
        _app(
          ActivityBar(
            selected: WorkspaceSection.manuscript,
            onSelect: picked.add,
            onBack: () => back++,
            onExport: () => exported++,
            sections: const [
              WorkspaceSection.overview,
              WorkspaceSection.manuscript,
              WorkspaceSection.elements,
            ],
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('elements.title'.tr()));
      await tester.tap(find.bySemanticsLabel('export.menu'.tr()));
      await tester.tap(find.bySemanticsLabel('workspace.back_to_library'.tr()));
      expect(picked, [WorkspaceSection.elements]);
      expect((exported, back), (1, 1));
    });

    testWidgets('sem exportação, o botão não aparece', (tester) async {
      await tester.pumpWidget(
        _app(
          ActivityBar(
            selected: WorkspaceSection.overview,
            onSelect: (_) {},
            onBack: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('export.menu'.tr()), findsNothing);
    });

    testWidgets('só a seção atual se anuncia como selecionada', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ActivityBar(
            selected: WorkspaceSection.manuscript,
            onSelect: (_) {},
            onBack: () {},
            sections: const [
              WorkspaceSection.overview,
              WorkspaceSection.manuscript,
            ],
          ),
        ),
      );
      SemanticsNode node(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node('workspace.manuscript'.tr()),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        node('workspace.overview'.tr()),
        isNot(isSemantics(isSelected: true)),
      );
      handle.dispose();
    });
  });

  group('SidePanel', () {
    testWidgets('mostra título, pincelada, ações e conteúdo', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 320,
            height: 400,
            child: SidePanel(
              title: 'Elementos',
              actions: [Icon(Icons.add)],
              child: Text('lista'),
            ),
          ),
        ),
      );
      expect(find.text('Elementos'), findsOneWidget);
      expect(find.byType(InkStroke), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('lista'), findsOneWidget);
    });
  });

  group('PanelListItem', () {
    Future<Color?> patch(WidgetTester tester, {required bool selected}) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: PanelListItem(
              icon: Icons.circle,
              label: 'Capítulo',
              subtitle: '10 palavras',
              selected: selected,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(PanelListItem),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (box.decoration! as BoxDecoration).color;
    }

    testWidgets('o selecionado repousa sobre uma mancha de tinta', (
      tester,
    ) async {
      final ink = GrisStages.dark[StageId.red]!.ink;
      expect(await patch(tester, selected: true), ink.withValues(alpha: .2));
      expect(await patch(tester, selected: false), ink.withValues(alpha: 0));
    });

    testWidgets('toca e mostra o subtítulo', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          PanelListItem(
            icon: Icons.circle,
            label: 'Capítulo',
            subtitle: '10 palavras',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Capítulo'));
      expect(taps, 1);
      expect(find.text('10 palavras'), findsOneWidget);
    });
  });
}
