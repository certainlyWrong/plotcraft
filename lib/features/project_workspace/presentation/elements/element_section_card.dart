import 'package:flutter/material.dart';

import '../../../../core/theme/plotcraft_tokens.dart';

/// Frame around one section of the element form, so the sections read as
/// separate blocks on the page.
class ElementSectionCard extends StatelessWidget {
  const ElementSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}
