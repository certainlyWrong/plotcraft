// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_fonts_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EditorFontsStore on _EditorFontsStore, Store {
  Computed<EditorFontCatalog>? _$catalogComputed;

  @override
  EditorFontCatalog get catalog =>
      (_$catalogComputed ??= Computed<EditorFontCatalog>(
        () => super.catalog,
        name: '_EditorFontsStore.catalog',
      )).value;

  late final _$projectFontsAtom = Atom(
    name: '_EditorFontsStore.projectFonts',
    context: context,
  );

  @override
  ObservableList<ProjectFont> get projectFonts {
    _$projectFontsAtom.reportRead();
    return super.projectFonts;
  }

  @override
  set projectFonts(ObservableList<ProjectFont> value) {
    _$projectFontsAtom.reportWrite(value, super.projectFonts, () {
      super.projectFonts = value;
    });
  }

  late final _$systemFamiliesAtom = Atom(
    name: '_EditorFontsStore.systemFamilies',
    context: context,
  );

  @override
  ObservableList<String> get systemFamilies {
    _$systemFamiliesAtom.reportRead();
    return super.systemFamilies;
  }

  @override
  set systemFamilies(ObservableList<String> value) {
    _$systemFamiliesAtom.reportWrite(value, super.systemFamilies, () {
      super.systemFamilies = value;
    });
  }

  late final _$projectKeyAtom = Atom(
    name: '_EditorFontsStore.projectKey',
    context: context,
  );

  @override
  String get projectKey {
    _$projectKeyAtom.reportRead();
    return super.projectKey;
  }

  @override
  set projectKey(String value) {
    _$projectKeyAtom.reportWrite(value, super.projectKey, () {
      super.projectKey = value;
    });
  }

  late final _$isBusyAtom = Atom(
    name: '_EditorFontsStore.isBusy',
    context: context,
  );

  @override
  bool get isBusy {
    _$isBusyAtom.reportRead();
    return super.isBusy;
  }

  @override
  set isBusy(bool value) {
    _$isBusyAtom.reportWrite(value, super.isBusy, () {
      super.isBusy = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    '_EditorFontsStore.load',
    context: context,
  );

  @override
  Future<void> load(StoryProject project) {
    return _$loadAsyncAction.run(() => super.load(project));
  }

  late final _$addAsyncAction = AsyncAction(
    '_EditorFontsStore.add',
    context: context,
  );

  @override
  Future<List<ProjectFont>> add(StoryProject project, List<String> paths) {
    return _$addAsyncAction.run(() => super.add(project, paths));
  }

  late final _$removeAsyncAction = AsyncAction(
    '_EditorFontsStore.remove',
    context: context,
  );

  @override
  Future<void> remove(StoryProject project, ProjectFont font) {
    return _$removeAsyncAction.run(() => super.remove(project, font));
  }

  @override
  String toString() {
    return '''
projectFonts: ${projectFonts},
systemFamilies: ${systemFamilies},
projectKey: ${projectKey},
isBusy: ${isBusy},
catalog: ${catalog}
    ''';
  }
}
