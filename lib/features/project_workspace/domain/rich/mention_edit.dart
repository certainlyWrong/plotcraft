import 'package:flutter/painting.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../narrative_element.dart';
import 'rich_document.dart';

/// Edits that create element mentions in a [QuillController]. A mention is
/// text carrying the inline `mention` attribute with the element's ID, so it
/// stays linked when the element is renamed.
abstract final class MentionEdit {
  static Attribute<Map<String, dynamic>> attribute(NarrativeElement element) =>
      Attribute<Map<String, dynamic>>(
        RichDocument.mentionKey,
        AttributeScope.inline,
        RichDocument.mention(element.id, element.title),
      );

  /// Replaces [length] characters at [index] (for example the typed `@`) with
  /// the element's name as a mention, followed by a plain space so that what
  /// the person types next is not part of the mention.
  static void insert(
    QuillController controller,
    int index,
    int length,
    NarrativeElement element,
  ) {
    final name = element.title;
    controller.replaceText(
      index,
      length,
      name,
      TextSelection.collapsed(offset: index + name.length),
    );
    controller.formatText(index, name.length, attribute(element));
    final after = index + name.length;
    controller.replaceText(
      after,
      0,
      ' ',
      TextSelection.collapsed(offset: after + 1),
    );
    // Inserted text inherits the style before it; the space must not.
    controller.formatText(after, 1, Attribute.clone(attribute(element), null));
  }

  /// Links the selected text to [element], keeping the text as written.
  /// Returns false when nothing is selected.
  static bool linkSelection(
    QuillController controller,
    NarrativeElement element,
  ) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return false;
    controller.formatText(
      selection.start,
      selection.end - selection.start,
      attribute(element),
    );
    return true;
  }

  /// Inserts a gallery image on its own line at the cursor.
  static void insertGalleryImage(QuillController controller, String id) =>
      _insertBlockEmbed(controller, RichDocument.galleryImage(id));

  static void insertDivider(QuillController controller) =>
      _insertBlockEmbed(controller, RichDocument.divider());

  /// Quill would put a custom embed in the middle of the current line, but an
  /// image or a divider belongs on a line of its own: a newline is added
  /// before it unless the cursor is at the start of a line, and after it
  /// unless the line already ends there.
  static void _insertBlockEmbed(
    QuillController controller,
    Map<String, dynamic> embed,
  ) {
    final selection = controller.selection;
    final index = selection.isValid ? selection.start : 0;
    final length = selection.isValid ? selection.end - selection.start : 0;
    final text = controller.document.toPlainText();
    final atLineStart = index == 0 || text[index - 1] == '\n';
    final end = index + length;
    final lineEndsHere = end >= text.length || text[end] == '\n';
    final delta = Delta()
      ..retain(index)
      ..delete(length);
    if (!atLineStart) delta.insert('\n');
    delta.insert(embed);
    if (!lineEndsHere) delta.insert('\n');
    controller.compose(
      delta,
      TextSelection.collapsed(offset: index + (atLineStart ? 0 : 1) + 1),
      ChangeSource.local,
    );
  }
}
