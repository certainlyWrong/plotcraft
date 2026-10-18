import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../stores/project_store.dart';
import '../../../../stores/theme_store.dart';
import '../../../../theme/interface_fonts.dart';
import '../../../../theme/theme_definition.dart';
import '../../../../ui/components/plotcraft_button.dart';
import '../../../../ui/components/plotcraft_dropdown.dart';
import '../../../../theme/plotcraft_tokens.dart';

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
      .showSnackBar(SnackBar(content: Text('preferences.folder_error'.tr())));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, pageConstraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'preferences.title'.tr(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
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
                          return ChoiceChip(
                            label: Text(_localeName(locale)),
                            selected: selected,
                            onSelected: (_) => context.setLocale(locale),
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
                          const SizedBox(height: 18),
                          fontPanel,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: languagePanel),
                        const SizedBox(width: 22),
                        Expanded(child: fontPanel),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
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
                const SizedBox(height: 22),
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
          .showSnackBar(SnackBar(content: Text('preferences.font_error'.tr())));
    }
  }
}

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
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (description != null) ...[
            const SizedBox(height: 7),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
    child: Container(
      width: 176,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 78,
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.surface ?? theme.background,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 38,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.surfaceRaised ?? theme.background,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(theme.name, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    ),
  );
}

String _localeName(Locale locale) => switch (locale.languageCode) {
  'en' => 'English',
  'pt' => 'Português',
  _ => locale.toString(),
};
