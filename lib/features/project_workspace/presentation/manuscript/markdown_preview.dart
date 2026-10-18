import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../domain/markdown_extensions.dart';
import '../../domain/narrative_element.dart';

/// Rendered Markdown. Element references become `plotcraft://element/<id>`
/// links and are reported through [onOpenElement].
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({
    super.key,
    required this.source,
    required this.elements,
    required this.projectFolder,
    required this.onOpenElement,
  });

  final String source;
  final List<NarrativeElement> elements;
  final String projectFolder;
  final ValueChanged<String> onOpenElement;

  static const _elementScheme = 'plotcraft://element/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pipeline = PlotcraftMarkdownPipeline([
      NarrativeLinkExtension(elements),
    ]);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: MarkdownBody(
            data: pipeline.preparePreview(source),
            selectable: true,
            imageDirectory: projectFolder.isEmpty
                ? null
                : Uri.directory(projectFolder).toString(),
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              a: theme.textTheme.bodyLarge?.copyWith(color: scheme.primary),
              p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              code: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Menlo',
                fontFamilyFallback: const ['Consolas', 'monospace'],
                backgroundColor: scheme.surfaceContainerHigh,
              ),
              codeblockDecoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outlineVariant),
              ),
              blockquoteDecoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(color: scheme.primary, width: 3),
                ),
              ),
            ),
            onTapLink: (_, href, _) {
              if (href?.startsWith(_elementScheme) ?? false) {
                onOpenElement(href!.substring(_elementScheme.length));
              }
            },
          ),
        ),
      ),
    );
  }
}
