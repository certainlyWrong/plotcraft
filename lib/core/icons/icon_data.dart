import 'package:flutter/widgets.dart';

import 'icon_catalog.g.dart';
import 'icon_ref.dart';

export 'icon_ref.dart';

/// Draws an [IconRef] with the generated catalog. A reference that is not in
/// the catalog shows [IconRef.fallback].
extension IconRefData on IconRef {
  IconData get data =>
      iconCatalog[set]?[name] ??
      iconCatalog[IconRef.fallback.set]![IconRef.fallback.name]!;
}
