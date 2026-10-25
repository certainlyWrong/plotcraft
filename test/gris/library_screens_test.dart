import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/plotcraft_tokens.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/core/ui/gris/gris.dart';
import 'package:plotcraft/features/projects/presentation/cover_palettes.dart';
import 'package:plotcraft/features/projects/presentation/widgets/project_empty_state.dart';
import 'package:plotcraft/features/projects/presentation/widgets/project_sidebar.dart';

Widget _app(Widget child) => MaterialApp(
  theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true, size: Size(1400, 900)),
    child: StageScope(
      stage: StageId.grey,
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  group('ProjectSidebar', () {
    ProjectSidebar sidebar({
      bool compact = false,
      bool projects = true,
      VoidCallback? onNew,
      VoidCallback? onPrefs,
    }) => ProjectSidebar(
      compact: compact,
      onProjects: () {},
      onNewProject: onNew ?? () {},
      onPreferences: onPrefs ?? () {},
      projectsSelected: projects,
      createSelected: !projects,
      preferencesSelected: false,
    );

    testWidgets('navega e sublinha só o lugar atual', (tester) async {
      var created = 0;
      var prefs = 0;
      await tester.pumpWidget(
        _app(sidebar(onNew: () => created++, onPrefs: () => prefs++)),
      );
      // One stroke of ink, under the page you are on.
      expect(find.byType(InkStroke), findsOneWidget);
      await tester.tap(find.text('home.new_project'.tr()));
      await tester.tap(find.text('preferences.title'.tr()));
      expect((created, prefs), (1, 1));
    });

    testWidgets('compacta, mostra só ícones e mantém os rótulos acessíveis', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(sidebar(compact: true)));
      expect(find.text('plotcraft'), findsNothing);
      expect(find.bySemanticsLabel('home.projects'.tr()), findsOneWidget);
      handle.dispose();
    });

    testWidgets('anuncia a página atual como selecionada', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(sidebar()));
      expect(
        tester.getSemantics(find.bySemanticsLabel('home.projects'.tr())),
        isSemantics(
          label: 'home.projects'.tr(),
          isSelected: true,
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('ProjectEmptyState', () {
    testWidgets('oferece criar projeto e abrir o exemplo', (tester) async {
      var created = 0;
      var sampled = 0;
      await tester.pumpWidget(
        _app(
          ProjectEmptyState(
            hasSearch: false,
            onCreate: () => created++,
            onSample: () => sampled++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrbitRings), findsOneWidget);
      await tester.tap(find.text('home.first_project'.tr()));
      await tester.tap(find.text('home.open_sample'.tr()));
      expect((created, sampled), (1, 1));
    });

    testWidgets('numa busca sem resultado não oferece criar', (tester) async {
      await tester.pumpWidget(
        _app(ProjectEmptyState(hasSearch: true, onCreate: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('home.first_project'.tr()), findsNothing);
    });
  });

  group('capas', () {
    test('há uma paleta por estágio, do pigmento à tinta', () {
      expect(coverPalettes, hasLength(StageId.values.length));
      for (var i = 0; i < StageId.values.length; i++) {
        final stage = GrisStages.dark[StageId.values[i]]!;
        expect(coverPalettes[i], [stage.pigment, stage.ink]);
      }
    });

    testWidgets('CoverWash pinta sem erro e se repinta com outra semente', (
      tester,
    ) async {
      Widget wash(int seed) => SizedBox(
        width: 200,
        height: 120,
        child: CoverWash(palette: coverPalettes[1], seed: seed),
      );
      await tester.pumpWidget(_app(wash(1)));
      await tester.pumpWidget(_app(wash(2)));
      expect(tester.takeException(), isNull);
    });
  });

  group('temas salvos', () {
    test('um id antigo escuro vira Gris Night e um claro vira Gris Day', () {
      expect(migrateThemeId('midnight'), 'gris-night');
      expect(migrateThemeId('violet-dark'), 'gris-night');
      expect(migrateThemeId('paper'), 'gris-day');
      expect(migrateThemeId('ocean'), 'gris-day');
    });

    test('um id atual ou desconhecido de usuário se mantém coerente', () {
      expect(migrateThemeId('gris-night'), 'gris-night');
      expect(migrateThemeId('gris-day'), 'gris-day');
      // Unknown ids (a user theme from assets/themes) fall back to light; the
      // store keeps the id itself if that theme is loaded.
      expect(migrateThemeId('ink-and-copper'), 'gris-day');
    });
  });
}
