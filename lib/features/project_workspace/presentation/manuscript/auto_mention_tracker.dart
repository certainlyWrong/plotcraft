import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/spellcheck/text_overlays.dart';
import '../../domain/narrative_element.dart';
import '../../domain/rich/mention_index.dart';

/// Keeps track of the names of elements written in plain text in a document
/// and draws a dotted underline under them. Like the spell checker it works
/// from the document without changing it: ranges move with every edit and are
/// recomputed after a pause in typing.
class AutoMentionTracker extends ChangeNotifier implements TextOverlaySource {
  AutoMentionTracker({
    this.debounce = const Duration(milliseconds: 400),
    List<NarrativeElement> elements = const [],
  }) {
    _elements = elements;
  }

  final Duration debounce;
  List<NarrativeElement> _elements = const [];
  QuillController? _controller;
  StreamSubscription<DocChange>? _changes;
  Timer? _timer;
  List<MentionHit> _hits = const [];
  bool _disposed = false;

  List<MentionHit> get hits => _hits;

  void attach(QuillController controller) {
    _changes?.cancel();
    _controller = controller;
    _changes = controller.document.changes.listen(_onChange);
    refresh();
  }

  /// A new list of elements (or new names) means the text must be re-read.
  set elements(List<NarrativeElement> value) {
    _elements = value;
    refresh();
  }

  void _onChange(DocChange change) {
    if (_hits.isNotEmpty) {
      final moved = <MentionHit>[];
      for (final hit in _hits) {
        final start = change.change.transformPosition(hit.start);
        final end = change.change.transformPosition(hit.end);
        if (end > start) {
          moved.add(
            MentionHit(
              start: start,
              end: end,
              elementId: hit.elementId,
              term: hit.term,
            ),
          );
        }
      }
      _set(moved);
    }
    schedule();
  }

  void schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, refreshNow);
  }

  void refresh() => schedule();

  void refreshNow() {
    final controller = _controller;
    if (controller == null || _disposed) return;
    final index = MentionIndex(_elements);
    _set(
      index.isEmpty
          ? const []
          : index.scan(controller.document.toDelta(), includeLinked: false),
    );
  }

  void _set(List<MentionHit> value) {
    if (_same(_hits, value)) return;
    _hits = value;
    if (!_disposed) notifyListeners();
  }

  bool _same(List<MentionHit> a, List<MentionHit> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// The detected name covering document [offset], if any.
  MentionHit? hitAt(int offset) {
    for (final hit in _hits) {
      if (offset >= hit.start && offset <= hit.end) return hit;
    }
    return null;
  }

  @override
  List<TextOverlay> overlays(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return [
      for (final hit in _hits)
        TextOverlay(
          hit.start,
          hit.end,
          TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: color,
          ),
        ),
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _changes?.cancel();
    super.dispose();
  }
}
