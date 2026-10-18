import 'package:mobx/mobx.dart';

import '../data/project_repository.dart';
import '../domain/project_format.dart';
import '../domain/story_project.dart';

part 'project_store.g.dart';

class ProjectStore = _ProjectStore with _$ProjectStore;

abstract class _ProjectStore with Store {
  _ProjectStore(this._repository);

  final ProjectRepository _repository;

  @observable
  ObservableList<StoryProject> projects = ObservableList<StoryProject>();

  @observable
  String query = '';

  @observable
  String sortBy = 'recent';

  /// Only projects of this format are listed; empty shows every format.
  @observable
  String formatFilter = '';

  @observable
  bool isLoaded = false;

  @observable
  String projectsRoot = '';

  @observable
  String defaultProjectsRoot = '';

  @computed
  List<StoryProject> get visibleProjects {
    final normalized = query.trim().toLowerCase();
    final result = projects.where((project) {
      if (formatFilter.isNotEmpty && project.primaryFormat != formatFilter) {
        return false;
      }
      return normalized.isEmpty ||
          project.title.toLowerCase().contains(normalized) ||
          project.subtitle.toLowerCase().contains(normalized) ||
          project.author.toLowerCase().contains(normalized) ||
          project.genre.toLowerCase().contains(normalized) ||
          project.tags.any((tag) => tag.toLowerCase().contains(normalized)) ||
          project.description.toLowerCase().contains(normalized);
    }).toList();
    if (sortBy == 'title') {
      result.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else {
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return result;
  }

  @action
  Future<void> load() async {
    defaultProjectsRoot = await _repository.defaultRoot;
    projectsRoot = await _repository.projectsRoot;
    projects = ObservableList.of(await _repository.load());
    isLoaded = true;
  }

  @action
  Future<void> selectProjectsRoot(String? path) async {
    await _repository.setProjectsRoot(path);
    projectsRoot = await _repository.projectsRoot;
  }

  @action
  Future<void> chooseProjectsRoot() async {
    if (await _repository.chooseProjectsRoot()) {
      projectsRoot = await _repository.projectsRoot;
    }
  }

  @action
  void setQuery(String value) => query = value;

  @action
  void setSort(String value) => sortBy = value;

  @action
  void setFormatFilter(String value) => formatFilter = value;

  /// Formats used by the projects in the library, in the registry's order.
  @computed
  List<String> get usedFormats => [
    for (final format in ProjectFormats.all)
      if (projects.any((project) => project.primaryFormat == format.id))
        format.id,
  ];

  @action
  void addCreated(StoryProject project) => projects.insert(0, project);

  @action
  void updateProject(StoryProject project) {
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index >= 0) projects[index] = project;
  }

  @action
  Future<void> delete(String id) async {
    final project = projects.firstWhere((item) => item.id == id);
    await _repository.delete(project);
    projects.remove(project);
  }
}
