// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_creation_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProjectCreationStore on _ProjectCreationStore, Store {
  late final _$isCreatingAtom = Atom(
    name: '_ProjectCreationStore.isCreating',
    context: context,
  );

  @override
  bool get isCreating {
    _$isCreatingAtom.reportRead();
    return super.isCreating;
  }

  @override
  set isCreating(bool value) {
    _$isCreatingAtom.reportWrite(value, super.isCreating, () {
      super.isCreating = value;
    });
  }

  late final _$createAsyncAction = AsyncAction(
    '_ProjectCreationStore.create',
    context: context,
  );

  @override
  Future<StoryProject> create(ProjectCreationInput input) {
    return _$createAsyncAction.run(() => super.create(input));
  }

  @override
  String toString() {
    return '''
isCreating: ${isCreating}
    ''';
  }
}
