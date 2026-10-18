import 'narrative_element.dart';

abstract class PlotcraftMarkdownExtension {
  const PlotcraftMarkdownExtension();

  String preparePreview(String source);
}

/// Stable links are stored by ID, so renaming an element never breaks links.
class NarrativeLinkExtension extends PlotcraftMarkdownExtension {
  const NarrativeLinkExtension(this.elements);

  final List<NarrativeElement> elements;

  static final RegExp linkPattern = RegExp(
    r'\[\[element:([A-Za-z0-9_-]+)(?:\|([^\]]+))?\]\]',
  );

  static String marker(NarrativeElement element, {String? label}) =>
      '[[element:${element.id}|${(label ?? element.title).replaceAll(RegExp(r'[\]\r\n]'), ' ')}]]';

  static bool references(String source, String id) =>
      linkPattern.allMatches(source).any((match) => match.group(1) == id);

  @override
  String preparePreview(String source) =>
      source.replaceAllMapped(linkPattern, (match) {
        final id = match.group(1)!;
        final element = elements.where((item) => item.id == id).firstOrNull;
        final label = match.group(2) ?? element?.title ?? id;
        return '[$label](plotcraft://element/$id)';
      });
}

class PlotcraftMarkdownPipeline {
  const PlotcraftMarkdownPipeline(this.extensions);

  final List<PlotcraftMarkdownExtension> extensions;

  String preparePreview(String source) => extensions.fold(
    source,
    (current, extension) => extension.preparePreview(current),
  );
}
