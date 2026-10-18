// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProjectStore on _ProjectStore, Store {
  Computed<List<StoryProject>>? _$visibleProjectsComputed;

  @override
  List<StoryProject> get visibleProjects =>
      (_$visibleProjectsComputed ??= Computed<List<StoryProject>>(
        () => super.visibleProjects,
        name: '_ProjectStore.visibleProjects',
      )).value;

  late final _$projectsAtom = Atom(
    name: '_ProjectStore.projects',
    context: context,
  );

  @override
  ObservableList<StoryProject> get projects {
    _$projectsAtom.reportRead();
    return super.projects;
  }

  @override
  set projects(ObservableList<StoryProject> value) {
    _$projectsAtom.reportWrite(value, super.projects, () {
      super.projects = value;
    });
  }

  late final _$queryAtom = Atom(name: '_ProjectStore.query', context: context);

  @override
  String get query {
    _$queryAtom.reportRead();
    return super.query;
  }

  @override
  set query(String value) {
    _$queryAtom.reportWrite(value, super.query, () {
      super.query = value;
    });
  }

  late final _$sortByAtom = Atom(
    name: '_ProjectStore.sortBy',
    context: context,
  );

  @override
  String get sortBy {
    _$sortByAtom.reportRead();
    return super.sortBy;
  }

  @override
  set sortBy(String value) {
    _$sortByAtom.reportWrite(value, super.sortBy, () {
      super.sortBy = value;
    });
  }

  late final _$isLoadedAtom = Atom(
    name: '_ProjectStore.isLoaded',
    context: context,
  );

  @override
  bool get isLoaded {
    _$isLoadedAtom.reportRead();
    return super.isLoaded;
  }

  @override
  set isLoaded(bool value) {
    _$isLoadedAtom.reportWrite(value, super.isLoaded, () {
      super.isLoaded = value;
    });
  }

  late final _$projectsRootAtom = Atom(
    name: '_ProjectStore.projectsRoot',
    context: context,
  );

  @override
  String get projectsRoot {
    _$projectsRootAtom.reportRead();
    return super.projectsRoot;
  }

  @override
  set projectsRoot(String value) {
    _$projectsRootAtom.reportWrite(value, super.projectsRoot, () {
      super.projectsRoot = value;
    });
  }

  late final _$defaultProjectsRootAtom = Atom(
    name: '_ProjectStore.defaultProjectsRoot',
    context: context,
  );

  @override
  String get defaultProjectsRoot {
    _$defaultProjectsRootAtom.reportRead();
    return super.defaultProjectsRoot;
  }

  @override
  set defaultProjectsRoot(String value) {
    _$defaultProjectsRootAtom.reportWrite(value, super.defaultProjectsRoot, () {
      super.defaultProjectsRoot = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    '_ProjectStore.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$selectProjectsRootAsyncAction = AsyncAction(
    '_ProjectStore.selectProjectsRoot',
    context: context,
  );

  @override
  Future<void> selectProjectsRoot(String? path) {
    return _$selectProjectsRootAsyncAction.run(
      () => super.selectProjectsRoot(path),
    );
  }

  late final _$chooseProjectsRootAsyncAction = AsyncAction(
    '_ProjectStore.chooseProjectsRoot',
    context: context,
  );

  @override
  Future<void> chooseProjectsRoot() {
    return _$chooseProjectsRootAsyncAction.run(
      () => super.chooseProjectsRoot(),
    );
  }

  late final _$deleteAsyncAction = AsyncAction(
    '_ProjectStore.delete',
    context: context,
  );

  @override
  Future<void> delete(String id) {
    return _$deleteAsyncAction.run(() => super.delete(id));
  }

  late final _$_ProjectStoreActionController = ActionController(
    name: '_ProjectStore',
    context: context,
  );

  @override
  void setQuery(String value) {
    final _$actionInfo = _$_ProjectStoreActionController.startAction(
      name: '_ProjectStore.setQuery',
    );
    try {
      return super.setQuery(value);
    } finally {
      _$_ProjectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSort(String value) {
    final _$actionInfo = _$_ProjectStoreActionController.startAction(
      name: '_ProjectStore.setSort',
    );
    try {
      return super.setSort(value);
    } finally {
      _$_ProjectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addCreated(StoryProject project) {
    final _$actionInfo = _$_ProjectStoreActionController.startAction(
      name: '_ProjectStore.addCreated',
    );
    try {
      return super.addCreated(project);
    } finally {
      _$_ProjectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateProject(StoryProject project) {
    final _$actionInfo = _$_ProjectStoreActionController.startAction(
      name: '_ProjectStore.updateProject',
    );
    try {
      return super.updateProject(project);
    } finally {
      _$_ProjectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
projects: ${projects},
query: ${query},
sortBy: ${sortBy},
isLoaded: ${isLoaded},
projectsRoot: ${projectsRoot},
defaultProjectsRoot: ${defaultProjectsRoot},
visibleProjects: ${visibleProjects}
    ''';
  }
}
