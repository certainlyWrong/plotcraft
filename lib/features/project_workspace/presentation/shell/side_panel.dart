import 'package:flutter/material.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/ink_stroke.dart';

/// Frame of the side panel: a serif title with a stroke of ink and the panel's
/// actions above [child]. The paper is slightly see-through, so the wash of the
/// current stage shows faintly behind the list.
class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surface.withValues(alpha: .7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: PlotcraftFonts.serif,
                          fontWeight: FontWeight.w500,
                          fontSize: 19,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const InkStroke(width: 64, delay: Duration.zero),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
