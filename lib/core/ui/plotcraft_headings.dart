import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';
import 'gris/ink_stroke.dart';
import 'gris/reveal.dart';

/// The title of a whole page: an eyebrow, a large serif title, a brushed
/// stroke of ink and a line of introduction, arriving one after the other.
class PlotcraftPageTitle extends StatelessWidget {
  const PlotcraftPageTitle({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
  });

  final String title;
  final String? eyebrow;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = context.tokens.ink;
    var step = 0;
    Widget stagger(Widget child) =>
        Reveal(delay: Reveal.staggerFor(step++), child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          stagger(
            Text(
              eyebrow!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2.4,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        stagger(
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: PlotcraftFonts.serif,
              fontSize: 42,
              fontWeight: FontWeight.w400,
              letterSpacing: -.8,
              height: 1.1,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        stagger(const InkStroke()),
        if (description != null) ...[
          const SizedBox(height: 14),
          stagger(
            Text(
              description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A titled stretch of a page, set on open paper rather than in a box: a serif
/// title, a short stroke of ink and an optional note, then the content.
class PlotcraftSection extends StatelessWidget {
  const PlotcraftSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.leading,
  });

  final String title;
  final String? description;
  final Widget child;

  /// A mark before the title, such as a numbered [MorphBadge].
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: PlotcraftFonts.serif,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const InkStroke(width: 72, delay: Duration.zero),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}
