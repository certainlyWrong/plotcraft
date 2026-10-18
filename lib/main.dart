import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/plotcraft_app.dart';
import 'data/local_storage.dart';
import 'data/project_repository.dart';
import 'features/project_creation/data/project_creation_service.dart';
import 'features/project_creation/stores/project_creation_store.dart';
import 'stores/project_store.dart';
import 'stores/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final supportedLocales = await _loadLocalesFromAssets();
  final preferences = await SharedPreferences.getInstance();
  final storage = LocalStorage(preferences);
  final creationService = ProjectCreationService();
  final repository = ProjectRepository(storage, creationService);
  final projects = ProjectStore(repository);
  final creation = ProjectCreationStore(
    repository,
    creationService,
    projects.addCreated,
  );
  final themes = ThemeStore(storage);
  await Future.wait([projects.load(), themes.load()]);

  final english = supportedLocales.firstWhere(
    (locale) => locale.languageCode == 'en',
    orElse: () => supportedLocales.first,
  );

  runApp(
    EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/translations',
      fallbackLocale: english,
      startLocale: english,
      saveLocale: true,
      useFallbackTranslations: true,
      child: PlotcraftApp(
        projects: projects,
        creation: creation,
        themes: themes,
      ),
    ),
  );
}

Future<List<Locale>> _loadLocalesFromAssets() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final locales = manifest
      .listAssets()
      .where(
        (path) =>
            path.startsWith('assets/translations/') && path.endsWith('.json'),
      )
      .map((path) => path.split('/').last.replaceFirst('.json', ''))
      .map((name) {
        final parts = name.split('-');
        return Locale.fromSubtags(
          languageCode: parts.first,
          countryCode: parts.length > 1 ? parts[1] : null,
        );
      })
      .toSet()
      .toList();

  if (locales.isEmpty) {
    throw StateError(
      'Add at least one locale file under assets/translations/.',
    );
  }
  return locales;
}
