import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;

import '../core/storage/local_storage.dart';
import '../features/projects/presentation/project_home_screen.dart';
import '../features/project_creation/stores/project_creation_store.dart';
import '../features/projects/stores/project_store.dart';
import '../features/preferences/stores/theme_store.dart';

class PlotcraftApp extends StatelessWidget {
  const PlotcraftApp({
    super.key,
    required this.projects,
    required this.creation,
    required this.themes,
    required this.storage,
  });

  final ProjectStore projects;
  final ProjectCreationStore creation;
  final ThemeStore themes;
  final LocalStorage storage;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plotcraft',
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeInOutCubic,
      theme: themes.selectedTheme.toThemeData(fontFamily: themes.fontFamily),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: [
        ...context.localizationDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      home: ProjectHomeScreen(
        projects: projects,
        creation: creation,
        themes: themes,
        storage: storage,
      ),
    ),
  );
}
