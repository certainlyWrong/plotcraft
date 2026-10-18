import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobx/mobx.dart';

import '../data/local_storage.dart';
import '../theme/interface_fonts.dart';
import '../theme/theme_definition.dart';

part 'theme_store.g.dart';

class ThemeStore = _ThemeStore with _$ThemeStore;

abstract class _ThemeStore with Store {
  _ThemeStore(this._storage);

  final LocalStorage _storage;

  @observable
  ObservableList<ThemeDefinition> themes = ObservableList.of(builtInThemes);

  @observable
  String selectedThemeId = 'violet';

  @observable
  String fontFamily = defaultInterfaceFont;

  @observable
  bool isLoadingFont = false;

  @computed
  ThemeDefinition get selectedTheme => themes.firstWhere(
    (theme) => theme.id == selectedThemeId,
    orElse: () => builtInThemes.first,
  );

  @action
  Future<void> load() async {
    selectedThemeId = _storage.loadTheme();
    final savedFontFamily = _storage.loadFontFamily();
    fontFamily = interfaceFonts.any((font) => font.family == savedFontFamily)
        ? savedFontFamily
        : defaultInterfaceFont;
    try {
      await _preloadFont(fontFamily);
    } catch (_) {
      fontFamily = defaultInterfaceFont;
      await _storage.saveFontFamily(defaultInterfaceFont);
    }
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final themePaths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/themes/') && path.endsWith('.json'),
            )
            .toList()
          ..sort();
    final loaded = <ThemeDefinition>[...builtInThemes];
    for (final path in themePaths) {
      try {
        final decoded = jsonDecode(await rootBundle.loadString(path));
        final theme = ThemeDefinition.fromJson(decoded as Map<String, dynamic>);
        if (loaded.every((existing) => existing.id != theme.id)) {
          loaded.add(theme);
        }
      } on FormatException {
        // Ignore malformed theme assets so one optional file cannot block startup.
      } on TypeError {
        // Ignore assets that do not match the theme schema.
      }
    }
    themes = ObservableList.of(loaded);
    if (themes.every((theme) => theme.id != selectedThemeId)) {
      selectedThemeId = builtInThemes.first.id;
    }
  }

  @action
  Future<void> select(String id) async {
    if (themes.any((theme) => theme.id == id)) {
      selectedThemeId = id;
      await _storage.saveTheme(id);
    }
  }

  @action
  Future<bool> selectFont(String family) async {
    if (!interfaceFonts.any((font) => font.family == family) || isLoadingFont) {
      return false;
    }
    isLoadingFont = true;
    try {
      await _preloadFont(family);
      await _storage.saveFontFamily(family);
      fontFamily = family;
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoadingFont = false;
    }
  }

  Future<void> _preloadFont(String family) async {
    if (family == defaultInterfaceFont) return;
    GoogleFonts.getTextTheme(family);
    await GoogleFonts.pendingFonts();
  }
}
