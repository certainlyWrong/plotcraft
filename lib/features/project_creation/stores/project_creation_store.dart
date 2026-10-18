import 'package:mobx/mobx.dart';

import '../../../data/project_repository.dart';
import '../../../models/story_project.dart';
import '../data/project_creation_service.dart';
import '../domain/project_creation_input.dart';

part 'project_creation_store.g.dart';

class ProjectCreationStore = _ProjectCreationStore with _$ProjectCreationStore;

abstract class _ProjectCreationStore with Store {
  _ProjectCreationStore(this._repository, this._service, this._onCreated);

  final ProjectRepository _repository;
  final ProjectCreationService _service;
  final void Function(StoryProject) _onCreated;

  @observable
  bool isCreating = false;

  @action
  Future<StoryProject> create(ProjectCreationInput input) async {
    if (isCreating) throw StateError('Project creation is already in progress');
    isCreating = true;
    try {
      input.validate();
      final project = await _service.create(
        input,
        await _repository.projectsRoot,
      );
      await _repository.register(project);
      _onCreated(project);
      return project;
    } finally {
      isCreating = false;
    }
  }
}
