import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../projects/stores/project_store.dart';
import '../stores/theme_store.dart';
import '../../../core/theme/interface_fonts.dart';
import '../../../core/theme/theme_definition.dart';
import '../../../core/ui/plotcraft_button.dart';
import '../../../core/ui/plotcraft_chip.dart';
import '../../../core/ui/plotcraft_headings.dart';
import '../../../core/ui/plotcraft_surface.dart';
import '../../../core/ui/plotcraft_dropdown.dart';
import '../../../core/theme/plotcraft_tokens.dart';
import '../../../core/ui/plotcraft_toast.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({
    super.key,
    required this.themes,
    required this.projects,
  });
  final ThemeStore themes;
  final ProjectStore projects;

  Future<void> _chooseProjectsFolder(BuildContext context) async {
    try {
      await projects.chooseProjectsRoot();
    } catch (error) {
      debugPrint('Project folder selection failed: $error');
      if (context.mounted) _showFolderError(context);
    }
  }

  Future<void> _resetProjectsFolder(BuildContext context) async {
    try {
      await projects.selectProjectsRoot(null);
    } catch (error) {
      debugPrint('Project folder reset failed: $error');
      if (context.mounted) _showFolderError(context);
    }
  }

  void _showFolderError(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(plotcraftToast(context, 'preferences.folder_error'.tr()));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, pageConstraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 44, 48, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlotcraftPageTitle(title: 'preferences.title'.tr()),
                const SizedBox(height: 44),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final languagePanel = _SettingsPanel(
                      title: 'preferences.language'.tr(),
                      child: Wrap(
                        spacing: 10,
                        children: context.supportedLocales.map((locale) {
                          final selected =
                              context.locale.languageCode ==
                              locale.languageCode;
                          return PlotcraftChip(
                            label: _localeName(locale),
                            selected: selected,
                            onTap: () => context.setLocale(locale),
                          );
                        }).toList(),
                      ),
                    );
                    final fontPanel = _SettingsPanel(
                      title: 'preferences.interface_font'.tr(),
                      description: 'preferences.font_description'.tr(),
                      child: Observer(
                        builder: (_) {
                          final fontFamily = themes.fontFamily;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlotcraftDropdown<String>(
                                key: ValueKey(fontFamily),
                                initialValue: fontFamily,
                                items: interfaceFonts
                                    .map(
                                      (font) => DropdownMenuItem(
                                        value: font.family,
                                        child: Text(
                                          font.isSystem
                                              ? 'preferences.default_font'.tr(
                                                  namedArgs: {
                                                    'font': font.family,
                                                  },
                                                )
                                              : font.family,
                                          style: TextStyle(
                                            fontFamily: font.family,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (family) {
                                  if (family != null) {
                                    _selectFont(context, family);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                    if (constraints.maxWidth < 850) {
                      return Column(
                        children: [
                          languagePanel,
                          const SizedBox(height: 44),
                          fontPanel,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: languagePanel),
                        const SizedBox(width: 56),
                        Expanded(child: fontPanel),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 44),
                _SettingsPanel(
                  title: 'preferences.theme'.tr(),
                  child: Observer(
                    builder: (_) => Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: themes.themes
                          .map(
                            (definition) => _ThemeChoice(
                              theme: definition,
                              selected: themes.selectedThemeId == definition.id,
                              onTap: () => themes.select(definition.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                _SettingsPanel(
                  title: 'preferences.projects_folder'.tr(),
                  description: 'preferences.projects_folder_description'.tr(),
                  child: Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(projects.projectsRoot),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            PlotcraftButton(
                              onPressed: () => _chooseProjectsFolder(context),
                              icon: Feather.folder,
                              label: 'preferences.choose_folder'.tr(),
                              variant: PlotcraftButtonVariant.secondary,
                            ),
                            if (projects.projectsRoot !=
                                projects.defaultProjectsRoot)
                              PlotcraftButton(
                                onPressed: () => _resetProjectsFolder(context),
                                label: 'preferences.reset_folder'.tr(),
                                variant: PlotcraftButtonVariant.text,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectFont(BuildContext context, String family) async {
    final loaded = await themes.selectFont(family);
    if (!loaded && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(plotcraftToast(context, 'preferences.font_error'.tr()));
    }
  }
}

/// One setting, set on open paper: a serif title with a stroke of ink, a note
/// and the control. Not a card.
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.child,
    this.description,
  });
  final String title;
  final String? description;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: PlotcraftSection(
      title: title,
      description: description,
      child: child,
    ),
  );
}

/// A theme shown as a small page of itself: its paper, its panels, and the
/// five pigments the journey passes through.
class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  final ThemeDefinition theme;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final stages = theme.isDark ? GrisStages.dark : GrisStages.light;
    return SizedBox(
      width: 200,
      child: PlotcraftSurface(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(PlotcraftRadii.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final stage in StageId.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: stages[stage]!.pigment,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.surface ?? theme.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 38,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.surfaceRaised ?? theme.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              theme.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFamily: PlotcraftFonts.serif,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _localeName(Locale locale) => switch (locale.languageCode) {
  'en' => 'English',
  'pt' => 'Português',
  _ => locale.toString(),
};
