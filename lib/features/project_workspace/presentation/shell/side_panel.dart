import 'package:flutter/material.dart';

/// Frame of the side panel: a header with a title and actions above [child].
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
    return Container(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w700,
                    ),
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
