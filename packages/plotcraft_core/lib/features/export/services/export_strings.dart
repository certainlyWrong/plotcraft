/// The few words the exported file writes itself.
class ExportStrings {
  const ExportStrings({
    required this.contents,
    required this.by,
    required this.unknownAuthor,
    required this.chapter,
  });

  final String contents;
  final String by;
  final String unknownAuthor;
  final String chapter;

  static const _en = ExportStrings(
    contents: 'Contents',
    by: 'by',
    unknownAuthor: 'Unknown author',
    chapter: 'Chapter',
  );
  static const _pt = ExportStrings(
    contents: 'Sumário',
    by: 'por',
    unknownAuthor: 'Autor desconhecido',
    chapter: 'Capítulo',
  );
  static const _es = ExportStrings(
    contents: 'Índice',
    by: 'por',
    unknownAuthor: 'Autor desconocido',
    chapter: 'Capítulo',
  );

  static ExportStrings of(String language) {
    final code = language.toLowerCase().split(RegExp('[-_]')).first;
    return switch (code) {
      'pt' => _pt,
      'es' => _es,
      _ => _en,
    };
  }
}
