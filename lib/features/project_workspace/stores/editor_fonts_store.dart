import 'package:mobx/mobx.dart';

import '../../../core/fonts/editor_font_catalog.dart';
import '../../../core/fonts/project_font_loader.dart';
import '../../../core/fonts/system_fonts.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft_core/features/project_workspace/domain/project_font.dart';

import '../presentation/manuscript/editor_fonts.dart';

part 'editor_fonts_store.g.dart';

/// Fonts available to the editor of one project: the bundled ones, the files
/// in the project's `fonts/` folder and the ones installed on this computer.
class EditorFontsStore = _EditorFontsStore with _$EditorFontsStore;

abstract class _EditorFontsStore with Store {
  _EditorFontsStore(this._repository, this._loader, this._systemFonts);

  final ProjectFontsRepository _repository;
  final ProjectFontLoader _loader;
  final SystemFontLister _systemFonts;

  @observable
  ObservableList<ProjectFont> projectFonts = ObservableList<ProjectFont>();

  @observable
  ObservableList<String> systemFamilies = ObservableList<String>();

  @observable
  String projectKey = '';

  @observable
  bool isBusy = false;

  /// Everything the editor needs to offer and draw fonts.
  @computed
  EditorFontCatalog get catalog => EditorFontCatalog(
    bundled: bundledEditorFontFamilies,
    project: {for (final font in projectFonts) font.family}.toList(),
    system: systemFamilies.toList(),
    projectKey: projectKey,
  );

  @action
  Future<void> load(StoryProject project) async {
    projectKey = project.id;
    await _refresh(project);
    final system = await _systemFonts.families();
    systemFamilies = ObservableList.of(system);
  }

  Future<void> _refresh(StoryProject project) async {
    final fonts = await _repository.list(project);
    await _loader.load(project.id, fonts.map((font) => font.path));
    projectFonts = ObservableList.of(fonts);
  }

  /// Copies font files into the project and makes them available. Returns
  /// the fonts that were added (files that are not fonts are skipped).
  @action
  Future<List<ProjectFont>> add(
    StoryProject project,
    List<String> paths,
  ) async {
    isBusy = true;
    try {
      final added = await _repository.add(project, paths);
      await _refresh(project);
      return added;
    } finally {
      isBusy = false;
    }
  }

  @action
  Future<void> remove(StoryProject project, ProjectFont font) async {
    isBusy = true;
    try {
      await _repository.remove(project, font.file);
      await _refresh(project);
    } finally {
      isBusy = false;
    }
  }
}
