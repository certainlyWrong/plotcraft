import 'package:flutter/material.dart';

import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import '../element_colors.dart';

/// Everything the element editor can change, held while the form is open. It
/// is turned into a [NarrativeElement] only when the person saves.
class ElementDraft {
  ElementDraft({required String typeId, NarrativeElement? element})
    : typeId = element?.typeId ?? typeId,
      title = TextEditingController(text: element?.title ?? ''),
      summary = TextEditingController(text: element?.summary ?? ''),
      aliases = [...?element?.aliases],
      tags = [...?element?.tags],
      icon = element?.icon,
      color = element?.color,
      images = [...?element?.images],
      fieldValues = {...?element?.fields},
      sections = [...?element?.sections],
      phases = [...?element?.phases],
      relations = [...?element?.relations],
      mentionPolicy = element?.mentionPolicy ?? const MentionPolicy();

  String typeId;
  final TextEditingController title;
  final TextEditingController summary;
  List<String> aliases;
  List<String> tags;
  IconRef? icon;
  Color? color;
  List<ElementImage> images;
  Map<String, String> fieldValues;
  List<NarrativeSection> sections;
  List<NarrativePhase> phases;
  List<ElementRelation> relations;
  MentionPolicy mentionPolicy;

  void dispose() {
    title.dispose();
    summary.dispose();
  }

  /// The element to save. [base] keeps the creation date of an existing one.
  NarrativeElement build({
    required String id,
    NarrativeElement? base,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    return NarrativeElement(
      id: id,
      typeId: typeId,
      title: title.text.trim(),
      aliases: aliases,
      summary: summary.text.trim(),
      tags: tags,
      icon: icon,
      colorValue: color?.toARGB32(),
      images: images,
      fields: Map.of(fieldValues)..removeWhere((_, value) => value.isEmpty),
      sections: sections,
      phases: phases,
      relations: relations,
      mentionPolicy: mentionPolicy,
      createdAt: base?.createdAt ?? time,
      updatedAt: time,
    );
  }
}
