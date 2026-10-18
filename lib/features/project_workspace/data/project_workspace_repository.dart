import '../../projects/domain/story_project.dart';
import '../domain/book_content.dart';
import '../domain/narrative_element.dart';
import 'book_repository.dart';
import 'gallery_repository.dart';
import 'narrative_repository.dart';
import 'project_files.dart';
import 'project_metadata_repository.dart';

class ProjectWorkspaceData {
  const ProjectWorkspaceData({
    required this.book,
    required this.elements,
    required this.galleryImages,
  });

  final BookContent book;
  final List<NarrativeElement> elements;
  final List<String> galleryImages;
}

/// Groups the repositories of one project folder and loads them together.
class ProjectWorkspaceRepository {
  ProjectWorkspaceRepository({ProjectFiles files = const ProjectFiles()})
    : _files = files,
      book = BookRepository(files),
      narrative = NarrativeRepository(files),
      gallery = GalleryRepository(files),
      metadata = ProjectMetadataRepository(files);

  final ProjectFiles _files;
  final BookRepository book;
  final NarrativeRepository narrative;
  final GalleryRepository gallery;
  final ProjectMetadataRepository metadata;

  Future<ProjectWorkspaceData> load(StoryProject project) async {
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    return ProjectWorkspaceData(
      book: await book.load(folder),
      elements: await narrative.load(folder),
      galleryImages: await gallery.list(project),
    );
  }
}
