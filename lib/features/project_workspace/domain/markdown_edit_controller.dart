import 'package:flutter/widgets.dart';

import 'markdown_extensions.dart';
import 'narrative_element.dart';

/// Text operations of the Markdown editor, kept apart from the widget so they
/// can be tested. Every mutating method edits the text controller in place.
class MarkdownEditController {
  const MarkdownEditController(this.text);

  final TextEditingController text;

  TextSelection get _selection {
    final value = text.value;
    return value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
  }

  /// Wraps the selection with [before] and [after] (for example `**`).
  void wrapSelection(String before, [String after = '']) {
    final value = text.value;
    final selection = _selection;
    final selected = selection.textInside(value.text);
    final start = selection.start + before.length;
    text.value = TextEditingValue(
      text:
          selection.textBefore(value.text) +
          before +
          selected +
          after +
          selection.textAfter(value.text),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + selected.length,
      ),
    );
  }

  void replaceSelection(String replacement) {
    final value = text.value;
    final selection = _selection;
    text.value = TextEditingValue(
      text:
          selection.textBefore(value.text) +
          replacement +
          selection.textAfter(value.text),
      selection: TextSelection.collapsed(
        offset: selection.start + replacement.length,
      ),
    );
  }

  /// Inserts [prefix] at the start of the line holding the cursor.
  void prefixLine(String prefix) {
    final value = text.value;
    final start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final lineStart = value.text.lastIndexOf('\n', start - 1) + 1;
    text.value = TextEditingValue(
      text: value.text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
  }

  /// Inserts a link to [element], using the selected text as its label.
  void insertElement(NarrativeElement element) {
    final selection = text.selection;
    final selected = selection.isValid
        ? selection.textInside(text.text).trim()
        : '';
    replaceSelection(
      NarrativeLinkExtension.marker(
        element,
        label: selected.isEmpty ? null : selected,
      ),
    );
  }

  /// Selects the next match after the cursor, wrapping around. False when the
  /// query is empty or absent.
  bool findNext(String query) {
    if (query.isEmpty) return false;
    final source = text.text.toLowerCase();
    final needle = query.toLowerCase();
    final from = text.selection.isValid ? text.selection.end : 0;
    var index = source.indexOf(needle, from);
    if (index < 0) index = source.indexOf(needle);
    if (index < 0) return false;
    text.selection = TextSelection(
      baseOffset: index,
      extentOffset: index + query.length,
    );
    return true;
  }

  /// Replaces the current match, if the selection is one, and finds the next.
  /// Returns true when the text changed.
  bool replaceCurrent(String query, String replacement) {
    final selection = text.selection;
    var changed = false;
    if (query.isNotEmpty &&
        selection.isValid &&
        selection.textInside(text.text).toLowerCase() == query.toLowerCase()) {
      replaceSelection(replacement);
      changed = true;
    }
    findNext(query);
    return changed;
  }
}
