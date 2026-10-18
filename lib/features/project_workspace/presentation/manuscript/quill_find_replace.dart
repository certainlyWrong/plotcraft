import 'package:flutter/painting.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Find and replace over the plain text of a [QuillController]. Searches ignore
/// case and wrap around the end of the document.
class QuillFindReplace {
  const QuillFindReplace(this.controller);

  final QuillController controller;

  String get _text => controller.document.toPlainText();

  /// Offsets of every match of [query].
  List<int> matches(String query) {
    if (query.isEmpty) return const [];
    final text = _text.toLowerCase();
    final needle = query.toLowerCase();
    final found = <int>[];
    for (
      var at = text.indexOf(needle);
      at >= 0;
      at = text.indexOf(needle, at + 1)
    ) {
      found.add(at);
    }
    return found;
  }

  /// Selects the next match after the cursor. False when there is none.
  bool findNext(String query) {
    if (query.isEmpty) return false;
    final text = _text.toLowerCase();
    final needle = query.toLowerCase();
    final selection = controller.selection;
    final from = selection.isValid ? selection.end : 0;
    var index = text.indexOf(needle, from);
    if (index < 0) index = text.indexOf(needle);
    if (index < 0) return false;
    controller.updateSelection(
      TextSelection(baseOffset: index, extentOffset: index + query.length),
      ChangeSource.local,
    );
    return true;
  }

  /// Replaces the selection if it is a match of [query], then selects the
  /// next one. Returns true when the text changed.
  bool replaceCurrent(String query, String replacement) {
    final selection = controller.selection;
    var changed = false;
    if (query.isNotEmpty && selection.isValid && !selection.isCollapsed) {
      final selected = _text.substring(selection.start, selection.end);
      if (selected.toLowerCase() == query.toLowerCase()) {
        controller.replaceText(
          selection.start,
          selection.end - selection.start,
          replacement,
          TextSelection.collapsed(offset: selection.start + replacement.length),
        );
        changed = true;
      }
    }
    findNext(query);
    return changed;
  }

  /// Replaces every match and returns how many were replaced.
  int replaceAll(String query, String replacement) {
    final offsets = matches(query);
    // From the end, so earlier offsets stay valid.
    for (final at in offsets.reversed) {
      controller.replaceText(
        at,
        query.length,
        replacement,
        TextSelection.collapsed(offset: at + replacement.length),
      );
    }
    return offsets.length;
  }
}
