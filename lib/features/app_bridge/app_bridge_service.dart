import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:plotcraft_core/features/app_bridge/app_bridge_server.dart';
import 'package:plotcraft_core/features/app_bridge/bridge_protocol.dart';

import '../../app/app_commands.dart';
import '../../core/platform/window_service.dart';
import '../../core/spellcheck/spell_check_backend.dart';
import '../../core/theme/interface_fonts.dart';
import '../preferences/stores/theme_store.dart';
import '../project_workspace/domain/workspace_tab.dart';
import '../projects/stores/project_store.dart';
import '../../core/platform/platform_support.dart';

/// Lets the MCP server (and so an AI) do the things only the running app can:
/// change preferences, open screens and use the system spell checker. It
/// answers the requests the server leaves in `<projects folder>/.plotcraft`.
class AppBridgeService {
  AppBridgeService({
    required this.projects,
    required this.themes,
    required this.commands,
    required this.languages,
    required this.currentLanguage,
    this.spell = const MethodChannelSpellCheckBackend(),
    this.version = '',
  });

  final ProjectStore projects;
  final ThemeStore themes;
  final AppCommands commands;
  final SpellCheckBackend spell;
  final String version;

  /// Language codes the app has translations for, and the one in use.
  final List<String> languages;
  final String Function() currentLanguage;

  AppBridgeServer? _server;
  ReactionDisposer? _rootReaction;

  /// Starts answering, and moves to the new folder when the projects folder
  /// changes.
  void start() {
    _restart();
    _rootReaction = reaction((_) => projects.projectsRoot, (_) => _restart());
  }

  Future<void> stop() async {
    _rootReaction?.call();
    await _server?.stop();
    _server = null;
  }

  void _restart() {
    unawaited(_server?.stop());
    final root = projects.projectsRoot;
    if (root.isEmpty) return;
    _server = AppBridgeServer(
      root,
      version: version,
      status: () => {
        'theme': themes.selectedThemeId,
        'interface_font': themes.fontFamily,
        'language': currentLanguage(),
        'open_project_id': commands.activeProjectId,
      },
      handlers: handlers,
    )..start();
  }

  Map<String, BridgeHandler> get handlers => {
    'get_preferences': (params) async => {
      'theme': themes.selectedThemeId,
      'themes': [for (final theme in themes.themes) theme.id],
      'interface_font': themes.fontFamily,
      'interface_fonts': [for (final font in interfaceFonts) font.family],
      'language': currentLanguage(),
      'languages': languages,
      'projects_folder': projects.projectsRoot,
      'open_project_id': commands.activeProjectId,
    },
    'list_themes': (params) async => {
      'selected': themes.selectedThemeId,
      'themes': [
        for (final theme in themes.themes)
          {'id': theme.id, 'name': theme.name, 'dark': theme.isDark},
      ],
    },
    'set_theme': (params) async {
      final id = _string(params, 'theme_id');
      if (!themes.themes.any((theme) => theme.id == id)) {
        throw BridgeError(
          'invalid_params',
          'There is no theme "$id". Use one of: '
              '${themes.themes.map((theme) => theme.id).join(', ')}.',
        );
      }
      await themes.select(id);
      return {'theme': themes.selectedThemeId};
    },
    'set_interface_font': (params) async {
      final family = _string(params, 'family');
      if (!await themes.selectFont(family)) {
        throw BridgeError(
          'invalid_params',
          'The font "$family" is not available. Use one of: '
              '${interfaceFonts.map((font) => font.family).join(', ')}.',
        );
      }
      return {'interface_font': themes.fontFamily};
    },
    'set_language': (params) async {
      final code = _string(params, 'language');
      if (!languages.contains(code)) {
        throw BridgeError(
          'invalid_params',
          'The language "$code" is not available. Use one of: '
              '${languages.join(', ')}.',
        );
      }
      final change = commands.setLocale;
      if (change == null) {
        throw const BridgeError(
          'internal',
          'The app cannot change language yet.',
        );
      }
      await change(Locale(code));
      return {'language': code};
    },
    'set_projects_root': (params) async {
      final path = _string(params, 'path');
      if (isMacOS) {
        throw const BridgeError(
          'unsupported',
          'On macOS the projects folder can only be chosen in the app '
              '(Preferences > Projects folder), because the system asks for '
              'permission to the folder there.',
        );
      }
      try {
        await projects.selectProjectsRoot(path);
      } on FileSystemException catch (error) {
        throw BridgeError('invalid_params', error.message);
      }
      return {'projects_folder': projects.projectsRoot};
    },
    'open_in_app': _openInApp,
    'spell_check': (params) async {
      _requireSpell();
      final text = _string(params, 'text');
      final locale = _locale(params['language']);
      final found = await spell.check(text, locale);
      return {
        'language': locale.toLanguageTag(),
        'misspellings': [
          for (final item in found.take(200))
            {
              'start': item.start,
              'end': item.end,
              'word': text.substring(item.start, item.end),
              'suggestions': (await spell.suggest(
                text.substring(item.start, item.end),
                locale,
              )).take(5).toList(),
            },
        ],
      };
    },
    'spell_suggest': (params) async {
      _requireSpell();
      final locale = _locale(params['language']);
      return {
        'suggestions': (await spell.suggest(
          _string(params, 'word'),
          locale,
        )).take(8).toList(),
      };
    },
    'spell_learn': (params) async {
      _requireSpell();
      final word = _string(params, 'word');
      await spell.learn(word);
      return {'learned': word};
    },
  };

  Future<Map<String, Object?>> _openInApp(Map<String, Object?> params) async {
    final id = _string(params, 'project_id');
    if (!projects.projects.any((project) => project.id == id)) {
      throw BridgeError(
        'invalid_params',
        'The app does not know project "$id".',
      );
    }
    final controller = await commands.openProject(id);
    if (controller == null) {
      throw const BridgeError('timeout', 'The project did not open in time.');
    }
    final chapterId = params['chapter_id'] as String?;
    final elementId = params['element_id'] as String?;
    if (chapterId != null) {
      if (!controller.store.book.chapters.any((c) => c.id == chapterId)) {
        throw BridgeError(
          'invalid_params',
          'There is no chapter "$chapterId".',
        );
      }
      final start = params['start'] as int?;
      final end = params['end'] as int?;
      controller.openManuscript(
        chapterId,
        reveal: start != null && end != null && end >= start
            ? TextRange(start: start, end: end)
            : null,
      );
    } else if (elementId != null) {
      if (!controller.store.elements.any((e) => e.id == elementId)) {
        throw BridgeError(
          'invalid_params',
          'There is no element "$elementId".',
        );
      }
      controller.openTab(WorkspaceTab.element(elementId));
    } else if (params['view'] is String) {
      final view = params['view'] as String;
      switch (view) {
        case 'settings':
          controller.openTab(WorkspaceTab.settings);
        case 'overview':
          controller.selectSection(WorkspaceSection.overview);
        case 'gallery':
          controller.selectSection(WorkspaceSection.gallery);
        case 'graph':
          controller.selectSection(WorkspaceSection.graph);
        case 'timeline':
          controller.selectSection(WorkspaceSection.timeline);
        default:
          throw BridgeError(
            'invalid_params',
            'There is no screen "$view". Use one of: overview, settings, '
                'gallery, graph, timeline.',
          );
      }
    }
    final fullscreen = params['fullscreen'];
    if (fullscreen is bool) {
      final active = controller.activeTab;
      if (fullscreen && (active == null || !active.supportsFullscreen)) {
        throw const BridgeError(
          'invalid_params',
          'Full screen is for the text editor, the map and the timeline: '
              'open one of them first.',
        );
      }
      await WindowService.setFullScreen(fullscreen);
      controller.toggleFullscreen(fullscreen);
    }
    return {
      'opened': true,
      'project_id': id,
      'chapter_id': chapterId,
      'element_id': elementId,
      'view': params['view'],
      'fullscreen': controller.editorFullscreen,
    };
  }

  void _requireSpell() {
    if (!MethodChannelSpellCheckBackend.isSupported) {
      throw const BridgeError(
        'unsupported',
        'The system spell checker is only available on macOS for now.',
      );
    }
  }

  static String _string(Map<String, Object?> params, String key) {
    final value = params[key];
    if (value is! String || value.isEmpty) {
      throw BridgeError('invalid_params', '"$key" is required.');
    }
    return value;
  }

  Locale _locale(Object? tag) {
    final value = (tag as String?) ?? currentLanguage();
    final parts = value.split(RegExp('[-_]'));
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }
}
