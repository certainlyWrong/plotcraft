import '../../projects/domain/story_project.dart';
import '../domain/book_content.dart';
import '../domain/element_type.dart';
import '../domain/gallery_item.dart';
import '../domain/narrative_migration.dart';
import '../domain/narrative_element.dart';
import 'book_repository.dart';
import 'element_types_repository.dart';
import 'gallery_repository.dart';
import 'narrative_repository.dart';
import 'project_files.dart';
import 'project_metadata_repository.dart';

class ProjectWorkspaceData {
  const ProjectWorkspaceData({
    required this.book,
    required this.elements,
    required this.galleryImages,
    this.types = const [],
    this.galleryItems = const [],
  });

  final BookContent book;
  final List<NarrativeElement> elements;
  final List<String> galleryImages;

  /// Custom element types (the built-in ones are not stored).
  final List<ElementType> types;

  /// Gallery images with stable IDs (missing files included).
  final List<GalleryItem> galleryItems;
}

/// Groups the repositories of one project folder and loads them together.
class ProjectWorkspaceRepository {
  ProjectWorkspaceRepository({ProjectFiles files = const ProjectFiles()})
    : _files = files,
      book = BookRepository(files),
      narrative = NarrativeRepository(files),
      gallery = GalleryRepository(files),
      metadata = ProjectMetadataRepository(files),
      types = ElementTypesRepository(files);

  final ProjectFiles _files;
  final BookRepository book;
  final NarrativeRepository narrative;
  final GalleryRepository gallery;
  final ProjectMetadataRepository metadata;
  final ElementTypesRepository types;

  Future<ProjectWorkspaceData> load(StoryProject project) async {
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    final upgrade = upgradeLegacyKinds(
      await narrative.load(folder),
      await types.load(folder),
    );
    // Old free-text kinds became custom types; save them so that elements
    // saved later never point to a type that only existed in memory.
    if (upgrade.typesChanged) {
      await types.save(project, upgrade.types, touch: false);
    }
    final galleryItems = await gallery.items(project);
    return ProjectWorkspaceData(
      book: await book.load(folder),
      elements: upgrade.elements,
      galleryImages: [
        for (final item in galleryItems)
          if (item.exists) item.path,
      ],
      galleryItems: galleryItems,
      types: upgrade.types,
    );
  }
}
