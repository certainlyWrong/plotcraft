import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/storage/local_storage.dart';
import 'package:plotcraft/features/projects/data/project_creation_service.dart';
import 'package:plotcraft/features/projects/data/project_repository.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';
import 'package:plotcraft/features/projects/stores/project_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

StoryProject _p(String id, String format, {String title = ''}) => StoryProject(
  id: id,
  title: title.isEmpty ? 'Projeto $id' : title,
  description: '',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 1, int.parse(id)),
  coverIndex: 0,
  primaryFormat: format,
);

void main() {
  late ProjectStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    store = ProjectStore(ProjectRepository(storage, ProjectCreationService()));
    store.projects.addAll([
      _p('1', 'book'),
      _p('2', 'manga', title: 'Berserk'),
      _p('3', 'book'),
    ]);
  });

  test('sem filtro lista tudo, do mais recente ao mais antigo', () {
    expect(store.visibleProjects.map((p) => p.id), ['3', '2', '1']);
  });

  test('o filtro mostra só o formato escolhido e combina com a busca', () {
    store.setFormatFilter('manga');
    expect(store.visibleProjects.map((p) => p.id), ['2']);
    store.setFormatFilter('book');
    expect(store.visibleProjects.map((p) => p.id), ['3', '1']);
    store.setQuery('berserk');
    expect(store.visibleProjects, isEmpty);
    store.setFormatFilter('');
    expect(store.visibleProjects.map((p) => p.id), ['2']);
  });

  test('usedFormats lista só os formatos presentes, na ordem do registro', () {
    expect(store.usedFormats, ['book', 'manga']);
    store.projects.removeWhere((p) => p.primaryFormat == 'manga');
    expect(store.usedFormats, ['book']);
  });
}
