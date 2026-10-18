import 'dart:ui';

import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

/// The colors of the domain models are plain ARGB numbers so that the models
/// work without Flutter; the interface reads them as [Color] through these.
extension NarrativeElementColor on NarrativeElement {
  Color? get color => colorValue == null ? null : Color(colorValue!);
}

extension ElementTypeColor on ElementType {
  Color get color => Color(colorValue);
}
