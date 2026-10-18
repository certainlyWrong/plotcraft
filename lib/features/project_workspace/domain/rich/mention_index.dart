import 'package:flutter_quill/quill_delta.dart';

import '../narrative_element.dart';
import 'rich_document.dart';

/// A place in a document where an element's name or alias appears.
class MentionHit {
  const MentionHit({
    required this.start,
    required this.end,
    required this.elementId,
    required this.term,
    this.linked = false,
  });

  /// Offsets into the document's plain text (an embed counts as one char).
  final int start;
  final int end;
  final String elementId;

  /// The name or alias that matched, as the element spells it.
  final String term;

  /// True when the text is already linked to the element with the mention
  /// attribute; false for a name found by the automatic detection.
  final bool linked;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is MentionHit &&
      other.start == start &&
      other.end == end &&
      other.elementId == elementId &&
      other.linked == linked;

  @override
  int get hashCode => Object.hash(start, end, elementId, linked);

  @override
  String toString() =>
      'MentionHit($elementId $start-$end ${linked ? 'linked' : 'auto'})';
}

/// Finds the elements named in a document: the explicit mentions the writer
/// created and, for elements that allow it, their names and aliases written
/// in plain text.
///
/// Matching ignores case and accents and only counts whole words, so "Lia"
/// is not found inside "Julia". Names shorter than [minTermLength] are
/// skipped because they match too much by accident.
class MentionIndex {
  MentionIndex(List<NarrativeElement> elements, {this.minTermLength = 3}) {
    final byTerm = <String, ({String id, String term})>{};
    for (final element in elements) {
      if (!element.mentionPolicy.auto) continue;
      final ignored = {
        for (final term in element.mentionPolicy.ignoredTerms) fold(term),
      };
      for (final term in [element.title, ...element.aliases]) {
        final folded = fold(term.trim());
        if (folded.runes.length < minTermLength ||
            ignored.contains(folded) ||
            !_startsWithLetterOrDigit(folded)) {
          continue;
        }
        // Two elements sharing a name: the first one wins.
        byTerm.putIfAbsent(
          _flexibleSpaces(folded),
          () => (id: element.id, term: term.trim()),
        );
      }
    }
    _byTerm = byTerm;
    if (byTerm.isEmpty) return;
    // Longest first so "Maria Clara" wins over "Maria".
    final terms = byTerm.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    _pattern = RegExp(
      r'(?<![\p{L}\p{N}])(?:' +
          terms.map(_escape).join('|') +
          r')(?![\p{L}\p{N}])',
      unicode: true,
    );
  }

  final int minTermLength;
  RegExp? _pattern;
  Map<String, ({String id, String term})> _byTerm = const {};

  bool get isEmpty => _pattern == null;

  /// Every hit in [delta], in order. Linked mentions are always included;
  /// automatic hits skip text that is already linked.
  List<MentionHit> scan(Delta delta, {bool includeLinked = true}) {
    final text = RichDocument.plainText(delta);
    final linked = _linkedRanges(delta);
    final hits = <MentionHit>[...(includeLinked ? linked : const [])];
    final pattern = _pattern;
    if (pattern != null) {
      final folded = fold(text);
      for (final match in pattern.allMatches(folded)) {
        if (linked.any((l) => match.start < l.end && match.end > l.start)) {
          continue;
        }
        final key = _flexibleSpaces(match.group(0)!);
        final found = _byTerm[key];
        if (found == null) continue;
        hits.add(
          MentionHit(
            start: match.start,
            end: match.end,
            elementId: found.id,
            term: found.term,
          ),
        );
      }
    }
    hits.sort((a, b) => a.start.compareTo(b.start));
    return hits;
  }

  static List<MentionHit> _linkedRanges(Delta delta) {
    final hits = <MentionHit>[];
    var offset = 0;
    for (final op in delta.toList()) {
      final data = op.data;
      final length = data is String ? data.length : 1;
      final mention = op.attributes?[RichDocument.mentionKey];
      if (data is String && mention is Map && mention['id'] is String) {
        hits.add(
          MentionHit(
            start: offset,
            end: offset + length,
            elementId: mention['id'] as String,
            term: data,
            linked: true,
          ),
        );
      }
      offset += length;
    }
    return hits;
  }

  /// Lower case without accents, with the same length as [text] so offsets
  /// in the result are offsets in the original.
  static String fold(String text) {
    final buffer = StringBuffer();
    for (final unit in text.codeUnits) {
      buffer.writeCharCode(_foldUnit(unit));
    }
    return buffer.toString();
  }

  static int _foldUnit(int unit) {
    if (unit < 0xC0) {
      return unit >= 0x41 && unit <= 0x5A ? unit + 32 : unit;
    }
    final mapped = _accents[unit];
    if (mapped != null) return mapped.codeUnitAt(0);
    return String.fromCharCode(unit).toLowerCase().codeUnitAt(0);
  }

  static final Map<int, String> _accents = () {
    const groups = {
      'a': 'àáâãäåāăąÀÁÂÃÄÅĀĂĄ',
      'c': 'çćĉċčÇĆĈĊČ',
      'd': 'ďđĎĐ',
      'e': 'èéêëēĕėęěÈÉÊËĒĔĖĘĚ',
      'g': 'ĝğġģĜĞĠĢ',
      'h': 'ĥħĤĦ',
      'i': 'ìíîïĩīĭįıÌÍÎÏĨĪĬĮİ',
      'j': 'ĵĴ',
      'k': 'ķĶ',
      'l': 'ĺļľŀłĹĻĽĿŁ',
      'n': 'ñńņňÑŃŅŇ',
      'o': 'òóôõöøōŏőÒÓÔÕÖØŌŎŐ',
      'r': 'ŕŗřŔŖŘ',
      's': 'śŝşšŚŜŞŠ',
      't': 'ţťŧŢŤŦ',
      'u': 'ùúûüũūŭůűųÙÚÛÜŨŪŬŮŰŲ',
      'w': 'ŵŴ',
      'y': 'ýÿŷÝŸŶ',
      'z': 'źżžŹŻŽ',
    };
    return {
      for (final entry in groups.entries)
        for (final rune in entry.value.runes) rune: entry.key,
    };
  }();

  static bool _startsWithLetterOrDigit(String text) =>
      RegExp(r'^[\p{L}\p{N}]', unicode: true).hasMatch(text);

  /// "maria  clara" and "maria clara" are the same name.
  static String _flexibleSpaces(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ');

  static String _escape(String term) =>
      RegExp.escape(term).replaceAll(' ', r'[ \t]+');
}
