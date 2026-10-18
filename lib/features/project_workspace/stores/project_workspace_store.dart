import 'package:mobx/mobx.dart';

import '../../projects/domain/story_project.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../data/book_repository.dart';
import '../data/project_workspace_repository.dart';
import '../domain/book_content.dart';
import '../domain/narrative_element.dart';

part 'project_workspace_store.g.dart';

class ProjectWorkspaceStore = _ProjectWorkspaceStore
    with _$ProjectWorkspaceStore;

abstract class _ProjectWorkspaceStore with Store {
  _ProjectWorkspaceStore(this._repository, this._onProjectUpdated);

  final ProjectWorkspaceRepository _repository;
  final void Function(StoryProject) _onProjectUpdated;

  @observable
  StoryProject? project;

  @observable
  BookContent book = const BookContent.empty();

  @observable
  ObservableList<NarrativeElement> elements =
      ObservableList<NarrativeElement>();

  @observable
  ObservableList<String> galleryImages = ObservableList<String>();

  @observable
  bool isLoading = false;

  @observable
  bool isSaving = false;

  @observable
  bool isImporting = false;

  @observable
  bool isUpdating = false;

  @observable
  bool isRemovingImage = false;

  @observable
  bool isBookUpdating = false;

  @observable
  bool isElementSaving = false;

  @computed
  String get manuscript => book.combinedText;

  @computed
  int get wordCount => book.wordCount;

  @action
  Future<void> load(StoryProject selected) async {
    isLoading = true;
    try {
      final data = await _repository.load(selected);
      project = selected;
      book = data.book;
      elements = ObservableList.of(data.elements);
      galleryImages = ObservableList.of(data.galleryImages);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> saveBookDocument(String? chapterId, String content) async {
    final current = project;
    if (current == null || isSaving) return;
    isSaving = true;
    try {
      final result = await _repository.book.saveBookDocument(
        current,
        book,
        chapterId,
        content,
      );
      _applyBookResult(result);
    } finally {
      isSaving = false;
    }
  }

  @action
  Future<void> setChapterMode(bool enabled) async {
    final current = project;
    if (current == null || isBookUpdating) return;
    isBookUpdating = true;
    try {
      _applyBookResult(
        await _repository.book.setChapterMode(current, book, enabled),
      );
    } finally {
      isBookUpdating = false;
    }
  }

  @action
  Future<String?> addChapter(String title) async {
    final current = project;
    if (current == null || isBookUpdating) return null;
    isBookUpdating = true;
    try {
      final result = await _repository.book.addChapter(current, book, title);
      _applyBookResult(result);
      return result.book.chapters.last.id;
    } finally {
      isBookUpdating = false;
    }
  }

  @action
  Future<void> updateChapters(List<BookChapter> chapters) async {
    final current = project;
    if (current == null || isBookUpdating) return;
    isBookUpdating = true;
    try {
      _applyBookResult(
        await _repository.book.updateChapters(current, book, chapters),
      );
    } finally {
      isBookUpdating = false;
    }
  }

  @action
  Future<void> removeChapter(String id) async {
    final current = project;
    if (current == null || isBookUpdating) return;
    isBookUpdating = true;
    try {
      _applyBookResult(await _repository.book.removeChapter(current, book, id));
    } finally {
      isBookUpdating = false;
    }
  }

  @action
  Future<void> saveElement(NarrativeElement element) async {
    final current = project;
    if (current == null || isElementSaving) {
      throw StateError('Element save is unavailable');
    }
    isElementSaving = true;
    try {
      final (updated, saved) = await _repository.narrative.saveElement(
        current,
        element,
      );
      project = updated;
      elements = ObservableList.of(
        [...elements.where((item) => item.id != saved.id), saved]..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        ),
      );
      _onProjectUpdated(updated);
    } finally {
      isElementSaving = false;
    }
  }

  @action
  Future<void> removeElement(String id) async {
    final current = project;
    if (current == null || isElementSaving) return;
    isElementSaving = true;
    try {
      final updated = await _repository.narrative.removeElement(current, id);
      project = updated;
      elements = ObservableList.of(elements.where((item) => item.id != id));
      _onProjectUpdated(updated);
    } finally {
      isElementSaving = false;
    }
  }

  void _applyBookResult(BookWriteResult result) {
    project = result.project;
    book = result.book;
    _onProjectUpdated(result.project);
  }

  @action
  Future<void> importImages(List<String> paths) async {
    final current = project;
    if (current == null || isImporting || paths.isEmpty) return;
    isImporting = true;
    try {
      final result = await _repository.gallery.importImages(current, paths);
      project = result.project;
      galleryImages = ObservableList.of(result.images);
      _onProjectUpdated(result.project);
    } finally {
      isImporting = false;
    }
  }

  @action
  Future<void> updateMetadata(
    ProjectMetadataInput input, {
    required bool removeCover,
  }) async {
    final current = project;
    if (current == null || isUpdating) return;
    isUpdating = true;
    try {
      final updated = await _repository.metadata.updateMetadata(
        current,
        input,
        removeCover: removeCover,
      );
      project = updated;
      _onProjectUpdated(updated);
    } finally {
      isUpdating = false;
    }
  }

  @action
  Future<void> removeImage(String imagePath) async {
    final current = project;
    if (current == null || isRemovingImage || isImporting) return;
    isRemovingImage = true;
    try {
      final result = await _repository.gallery.removeImage(current, imagePath);
      project = result.project;
      galleryImages = ObservableList.of(result.images);
      _onProjectUpdated(result.project);
    } finally {
      isRemovingImage = false;
    }
  }
}
