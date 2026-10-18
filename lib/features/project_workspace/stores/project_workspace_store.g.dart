// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_workspace_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProjectWorkspaceStore on _ProjectWorkspaceStore, Store {
  Computed<List<ElementType>>? _$elementTypesComputed;

  @override
  List<ElementType> get elementTypes =>
      (_$elementTypesComputed ??= Computed<List<ElementType>>(
        () => super.elementTypes,
        name: '_ProjectWorkspaceStore.elementTypes',
      )).value;
  Computed<String>? _$manuscriptComputed;

  @override
  String get manuscript => (_$manuscriptComputed ??= Computed<String>(
    () => super.manuscript,
    name: '_ProjectWorkspaceStore.manuscript',
  )).value;
  Computed<int>? _$wordCountComputed;

  @override
  int get wordCount => (_$wordCountComputed ??= Computed<int>(
    () => super.wordCount,
    name: '_ProjectWorkspaceStore.wordCount',
  )).value;

  late final _$projectAtom = Atom(
    name: '_ProjectWorkspaceStore.project',
    context: context,
  );

  @override
  StoryProject? get project {
    _$projectAtom.reportRead();
    return super.project;
  }

  @override
  set project(StoryProject? value) {
    _$projectAtom.reportWrite(value, super.project, () {
      super.project = value;
    });
  }

  late final _$bookAtom = Atom(
    name: '_ProjectWorkspaceStore.book',
    context: context,
  );

  @override
  BookContent get book {
    _$bookAtom.reportRead();
    return super.book;
  }

  @override
  set book(BookContent value) {
    _$bookAtom.reportWrite(value, super.book, () {
      super.book = value;
    });
  }

  late final _$elementsAtom = Atom(
    name: '_ProjectWorkspaceStore.elements',
    context: context,
  );

  @override
  ObservableList<NarrativeElement> get elements {
    _$elementsAtom.reportRead();
    return super.elements;
  }

  @override
  set elements(ObservableList<NarrativeElement> value) {
    _$elementsAtom.reportWrite(value, super.elements, () {
      super.elements = value;
    });
  }

  late final _$customElementTypesAtom = Atom(
    name: '_ProjectWorkspaceStore.customElementTypes',
    context: context,
  );

  @override
  ObservableList<ElementType> get customElementTypes {
    _$customElementTypesAtom.reportRead();
    return super.customElementTypes;
  }

  @override
  set customElementTypes(ObservableList<ElementType> value) {
    _$customElementTypesAtom.reportWrite(value, super.customElementTypes, () {
      super.customElementTypes = value;
    });
  }

  late final _$galleryImagesAtom = Atom(
    name: '_ProjectWorkspaceStore.galleryImages',
    context: context,
  );

  @override
  ObservableList<String> get galleryImages {
    _$galleryImagesAtom.reportRead();
    return super.galleryImages;
  }

  @override
  set galleryImages(ObservableList<String> value) {
    _$galleryImagesAtom.reportWrite(value, super.galleryImages, () {
      super.galleryImages = value;
    });
  }

  late final _$galleryItemsAtom = Atom(
    name: '_ProjectWorkspaceStore.galleryItems',
    context: context,
  );

  @override
  ObservableList<GalleryItem> get galleryItems {
    _$galleryItemsAtom.reportRead();
    return super.galleryItems;
  }

  @override
  set galleryItems(ObservableList<GalleryItem> value) {
    _$galleryItemsAtom.reportWrite(value, super.galleryItems, () {
      super.galleryItems = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_ProjectWorkspaceStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isSavingAtom = Atom(
    name: '_ProjectWorkspaceStore.isSaving',
    context: context,
  );

  @override
  bool get isSaving {
    _$isSavingAtom.reportRead();
    return super.isSaving;
  }

  @override
  set isSaving(bool value) {
    _$isSavingAtom.reportWrite(value, super.isSaving, () {
      super.isSaving = value;
    });
  }

  late final _$isImportingAtom = Atom(
    name: '_ProjectWorkspaceStore.isImporting',
    context: context,
  );

  @override
  bool get isImporting {
    _$isImportingAtom.reportRead();
    return super.isImporting;
  }

  @override
  set isImporting(bool value) {
    _$isImportingAtom.reportWrite(value, super.isImporting, () {
      super.isImporting = value;
    });
  }

  late final _$isUpdatingAtom = Atom(
    name: '_ProjectWorkspaceStore.isUpdating',
    context: context,
  );

  @override
  bool get isUpdating {
    _$isUpdatingAtom.reportRead();
    return super.isUpdating;
  }

  @override
  set isUpdating(bool value) {
    _$isUpdatingAtom.reportWrite(value, super.isUpdating, () {
      super.isUpdating = value;
    });
  }

  late final _$isRemovingImageAtom = Atom(
    name: '_ProjectWorkspaceStore.isRemovingImage',
    context: context,
  );

  @override
  bool get isRemovingImage {
    _$isRemovingImageAtom.reportRead();
    return super.isRemovingImage;
  }

  @override
  set isRemovingImage(bool value) {
    _$isRemovingImageAtom.reportWrite(value, super.isRemovingImage, () {
      super.isRemovingImage = value;
    });
  }

  late final _$isBookUpdatingAtom = Atom(
    name: '_ProjectWorkspaceStore.isBookUpdating',
    context: context,
  );

  @override
  bool get isBookUpdating {
    _$isBookUpdatingAtom.reportRead();
    return super.isBookUpdating;
  }

  @override
  set isBookUpdating(bool value) {
    _$isBookUpdatingAtom.reportWrite(value, super.isBookUpdating, () {
      super.isBookUpdating = value;
    });
  }

  late final _$isElementSavingAtom = Atom(
    name: '_ProjectWorkspaceStore.isElementSaving',
    context: context,
  );

  @override
  bool get isElementSaving {
    _$isElementSavingAtom.reportRead();
    return super.isElementSaving;
  }

  @override
  set isElementSaving(bool value) {
    _$isElementSavingAtom.reportWrite(value, super.isElementSaving, () {
      super.isElementSaving = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.load',
    context: context,
  );

  @override
  Future<void> load(StoryProject selected) {
    return _$loadAsyncAction.run(() => super.load(selected));
  }

  late final _$saveBookDocumentAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.saveBookDocument',
    context: context,
  );

  @override
  Future<void> saveBookDocument(String? chapterId, String content) {
    return _$saveBookDocumentAsyncAction.run(
      () => super.saveBookDocument(chapterId, content),
    );
  }

  late final _$setChapterModeAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.setChapterMode',
    context: context,
  );

  @override
  Future<void> setChapterMode(bool enabled) {
    return _$setChapterModeAsyncAction.run(() => super.setChapterMode(enabled));
  }

  late final _$addChapterAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.addChapter',
    context: context,
  );

  @override
  Future<String?> addChapter(String title) {
    return _$addChapterAsyncAction.run(() => super.addChapter(title));
  }

  late final _$updateChaptersAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.updateChapters',
    context: context,
  );

  @override
  Future<void> updateChapters(List<BookChapter> chapters) {
    return _$updateChaptersAsyncAction.run(
      () => super.updateChapters(chapters),
    );
  }

  late final _$removeChapterAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.removeChapter',
    context: context,
  );

  @override
  Future<void> removeChapter(String id) {
    return _$removeChapterAsyncAction.run(() => super.removeChapter(id));
  }

  late final _$saveElementAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.saveElement',
    context: context,
  );

  @override
  Future<void> saveElement(NarrativeElement element) {
    return _$saveElementAsyncAction.run(() => super.saveElement(element));
  }

  late final _$saveElementTypeAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.saveElementType',
    context: context,
  );

  @override
  Future<void> saveElementType(ElementType type) {
    return _$saveElementTypeAsyncAction.run(() => super.saveElementType(type));
  }

  late final _$removeElementTypeAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.removeElementType',
    context: context,
  );

  @override
  Future<void> removeElementType(String id) {
    return _$removeElementTypeAsyncAction.run(
      () => super.removeElementType(id),
    );
  }

  late final _$removeElementAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.removeElement',
    context: context,
  );

  @override
  Future<void> removeElement(String id) {
    return _$removeElementAsyncAction.run(() => super.removeElement(id));
  }

  late final _$importImagesAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.importImages',
    context: context,
  );

  @override
  Future<void> importImages(List<String> paths) {
    return _$importImagesAsyncAction.run(() => super.importImages(paths));
  }

  late final _$updateMetadataAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.updateMetadata',
    context: context,
  );

  @override
  Future<void> updateMetadata(
    ProjectMetadataInput input, {
    required bool removeCover,
  }) {
    return _$updateMetadataAsyncAction.run(
      () => super.updateMetadata(input, removeCover: removeCover),
    );
  }

  late final _$removeImageAsyncAction = AsyncAction(
    '_ProjectWorkspaceStore.removeImage',
    context: context,
  );

  @override
  Future<void> removeImage(String imagePath) {
    return _$removeImageAsyncAction.run(() => super.removeImage(imagePath));
  }

  @override
  String toString() {
    return '''
project: ${project},
book: ${book},
elements: ${elements},
customElementTypes: ${customElementTypes},
galleryImages: ${galleryImages},
galleryItems: ${galleryItems},
isLoading: ${isLoading},
isSaving: ${isSaving},
isImporting: ${isImporting},
isUpdating: ${isUpdating},
isRemovingImage: ${isRemovingImage},
isBookUpdating: ${isBookUpdating},
isElementSaving: ${isElementSaving},
elementTypes: ${elementTypes},
manuscript: ${manuscript},
wordCount: ${wordCount}
    ''';
  }
}
