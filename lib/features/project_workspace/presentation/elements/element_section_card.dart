import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_surface.dart';

/// Frame around one section of the element form, so the sections read as
/// separate sheets of paper on the page.
class ElementSectionCard extends StatelessWidget {
  const ElementSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: PlotcraftSurface(padding: const EdgeInsets.all(22), child: child),
  );
}
