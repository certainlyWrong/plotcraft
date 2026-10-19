import 'package:flutter/widgets.dart';

import 'package:plotcraft_core/features/project_workspace/domain/active_phase.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/gallery_item.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import 'element_hover_card.dart';
import 'mention_hover_controller.dart';

/// The card shown over a mention of [id], or null if the element is gone.
/// Shared by the editor and the reader.
Widget? mentionCard({
  required String id,
  required bool auto,
  required List<NarrativeElement> elements,
  required List<ElementType> types,
  required List<GalleryItem> galleryItems,
  required List<String> chapterOrder,
  required String? chapterId,
  String? Function(String file)? attachmentPath,
}) {
  final element = elements.where((e) => e.id == id).firstOrNull;
  if (element == null) return null;
  final cover = element.images.firstOrNull;
  String? coverPath;
  if (cover != null) {
    if (cover.isGallery) {
      final item = galleryItems.where((i) => i.id == cover.value).firstOrNull;
      coverPath = item != null && item.exists ? item.path : null;
    } else {
      coverPath = attachmentPath?.call(cover.value);
    }
  }
  return ElementHoverCard(
    element: element,
    type: ElementTypeCatalog.resolve(element.typeId, types),
    coverPath: coverPath,
    phase: activePhaseAt(element, chapterOrder, chapterId),
    auto: auto,
  );
}

/// Makes every piece of a mention's text report the pointer entering and
/// leaving, so its card can be shown.
InlineSpan withMentionHover(
  InlineSpan span,
  String id,
  MentionHoverController hover,
) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text,
    style: span.style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: (event) => hover.enter(id, event.position),
    onExit: (_) => hover.leave(),
    children: [
      for (final child in span.children ?? const <InlineSpan>[])
        withMentionHover(child, id, hover),
    ],
  );
}
