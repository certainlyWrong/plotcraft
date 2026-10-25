import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  static const _projectsKey = 'plotcraft.projects.v1';
  static const _projectDirectoriesKey = 'plotcraft.project_directories.v1';
  static const _projectsRootKey = 'plotcraft.projects_root.v1';
  static const _folderBookmarksKey = 'plotcraft.folder_bookmarks.v1';
  static const _themeKey = 'plotcraft.theme';
  static const _fontFamilyKey = 'plotcraft.interface_font_family';

  /// Raw project records saved by versions that kept the library in
  /// preferences. The projects feature turns them into folders.
  List<Map<String, dynamic>> loadLegacyProjects() {
    final value = _preferences.getString(_projectsKey);
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  List<String> loadProjectDirectories() =>
      _preferences.getStringList(_projectDirectoriesKey) ?? const [];

  Future<void> saveProjectDirectories(List<String> paths) =>
      _preferences.setStringList(_projectDirectoriesKey, paths);

  String? loadProjectsRoot() => _preferences.getString(_projectsRootKey);

  Future<void> saveProjectsRoot(String? path) async {
    if (path == null) {
      await _preferences.remove(_projectsRootKey);
    } else {
      await _preferences.setString(_projectsRootKey, path);
    }
  }

  Future<void> clearLegacyProjects() => _preferences.remove(_projectsKey);

  Map<String, String> loadFolderBookmarks() {
    final value = _preferences.getString(_folderBookmarksKey);
    if (value == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(value) as Map);
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> saveFolderBookmarks(Map<String, String> bookmarks) =>
      _preferences.setString(_folderBookmarksKey, jsonEncode(bookmarks));

  String? loadString(String key) => _preferences.getString('plotcraft.$key');

  Future<void> saveString(String key, String value) =>
      _preferences.setString('plotcraft.$key', value);

  double? loadDouble(String key) => _preferences.getDouble('plotcraft.$key');

  Future<void> saveDouble(String key, double value) =>
      _preferences.setDouble('plotcraft.$key', value);

  String loadTheme() => _preferences.getString(_themeKey) ?? 'gris-night';
  Future<void> saveTheme(String value) =>
      _preferences.setString(_themeKey, value);

  String loadFontFamily() =>
      _preferences.getString(_fontFamilyKey) ?? 'Times New Roman';
  Future<void> saveFontFamily(String value) =>
      _preferences.setString(_fontFamilyKey, value);
}
