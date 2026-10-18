import 'package:easy_localization/easy_localization.dart';

import '../../domain/element_type.dart';

extension ElementTypeLabel on ElementType {
  /// Built-in types are translated; custom ones show the name they were given.
  String get label => nameKey != null ? nameKey!.tr() : name;
}

extension ElementFieldLabel on ElementField {
  String get displayLabel => labelKey != null ? labelKey!.tr() : label;
}
