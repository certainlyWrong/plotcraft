import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/core/theme/argb_hex.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/gallery_item.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/project_font.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

/// JSON shapes of the tool results. Keys are `snake_case`; ids and revisions
/// are always present so the AI can pass them back.

Map<String, Object?> projectJson(StoryProject project) => {
  'id': project.id,
  'title': project.title,
  'subtitle': project.subtitle,
  'author': project.author,
  'genre': project.genre,
  'description': project.description,
  'tags': project.tags,
  'format': project.primaryFormat,
  'cover_color_index': project.coverIndex,
  'has_cover_image': project.coverFile != null,
  'folder': project.directoryPath,
  'created_at': project.createdAt.toIso8601String(),
  'updated_at': project.updatedAt.toIso8601String(),
};

Map<String, Object?> chapterInfoJson(ChapterInfo chapter) => {
  'id': chapter.id,
  'title': chapter.title,
  'position': chapter.index,
  'words': chapter.words,
  'revision': chapter.revision,
};

/// English name of a type (built-in names are translation keys in the app).
String typeName(ElementType type) =>
    type.builtin ? _titleCase(type.id) : type.name;

String fieldLabel(ElementField field) => field.labelKey != null
    ? _titleCase(field.labelKey!.split('.').last)
    : field.label;

String _titleCase(String id) =>
    id.isEmpty ? id : '${id[0].toUpperCase()}${id.substring(1)}';

Map<String, Object?> iconJson(IconRef icon) => {
  'set': icon.set,
  'name': icon.name,
};

Map<String, Object?> typeJson(ElementType type) => {
  'id': type.id,
  'name': typeName(type),
  'built_in': type.builtin,
  'icon': iconJson(type.icon),
  'color': argbToHex(type.colorValue),
  'fields': [
    for (final field in type.fields)
      {
        'id': field.id,
        'label': fieldLabel(field),
        'kind': field.kind.name,
        if (field.options.isNotEmpty) 'options': field.options,
      },
  ],
};

Map<String, Object?> galleryJson(GalleryItem item) => {
  'id': item.id,
  'file': item.file,
  'path': item.path,
  'exists': item.exists,
};

Map<String, Object?> fontJson(ProjectFont font) => {
  'file': font.file,
  'family': font.family,
  'style': font.style,
  'path': font.path,
};

Map<String, Object?> anchorJson(NarrativeAnchor anchor) =>
    switch (anchor.kind) {
      NarrativeAnchorKind.none => {'kind': 'none'},
      NarrativeAnchorKind.chapter => {
        'kind': 'chapter',
        'chapter_id': anchor.value,
      },
      NarrativeAnchorKind.manual => {'kind': 'manual', 'label': anchor.value},
    };

Map<String, Object?> imageJson(ElementImage image) =>
    image.isGallery ? {'gallery_id': image.value} : {'attachment': image.value};

Map<String, Object?> relationJson(ElementRelation relation) => {
  'id': relation.id,
  'target_id': relation.targetId,
  'label': relation.label,
  'reciprocal_label': relation.reciprocalLabel,
  'note': relation.note,
};

/// Everything stored about an element, plus the revision of its file.
Map<String, Object?> elementJson(ElementRecord record) {
  final element = record.element;
  return {
    'id': element.id,
    'type': element.typeId,
    'title': element.title,
    'summary': element.summary,
    'aliases': element.aliases,
    'tags': element.tags,
    'icon': element.icon == null ? null : iconJson(element.icon!),
    'color': element.colorValue == null ? null : argbToHex(element.colorValue!),
    'fields': element.fields,
    'sections': [
      for (final section in element.sections)
        {
          'id': section.id,
          'title': section.title,
          'markdown': section.markdown,
        },
    ],
    'phases': [
      for (final phase in element.phases)
        {
          'id': phase.id,
          'title': phase.title,
          'description': phase.description,
          'anchor': anchorJson(phase.anchor),
          'field_overrides': phase.fieldOverrides,
          'image': phase.image == null ? null : imageJson(phase.image!),
        },
    ],
    'relations': [for (final r in element.relations) relationJson(r)],
    'images': [for (final image in element.images) imageJson(image)],
    'mention_policy': {
      'auto': element.mentionPolicy.auto,
      'ignored_terms': element.mentionPolicy.ignoredTerms,
    },
    'created_at': element.createdAt.toIso8601String(),
    'updated_at': element.updatedAt.toIso8601String(),
    'revision': record.revision,
  };
}

/// A short line for lists of elements.
Map<String, Object?> elementSummaryJson(ElementRecord record) {
  final element = record.element;
  return {
    'id': element.id,
    'type': element.typeId,
    'title': element.title,
    'summary': element.summary,
    'aliases': element.aliases,
    'tags': element.tags,
    'revision': record.revision,
  };
}

Map<String, Object?> occurrenceJson(MentionOccurrence occurrence) => {
  'chapter_id': occurrence.chapterId,
  'chapter_title': occurrence.chapterTitle,
  'start': occurrence.start,
  'end': occurrence.end,
  'snippet': occurrence.snippet,
  'linked': occurrence.linked,
};
