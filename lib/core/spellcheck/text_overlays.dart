import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A style laid over a stretch of the document (document offsets).
class TextOverlay {
  const TextOverlay(
    this.start,
    this.end,
    this.style, {
    this.onEnter,
    this.onExit,
  });

  final int start;
  final int end;
  final TextStyle style;

  /// Called when a mouse pointer enters or leaves the covered text.
  final void Function(PointerEnterEvent event)? onEnter;
  final void Function(PointerExitEvent event)? onExit;
}

/// Something that decorates stretches of text without changing the document:
/// misspelled words, names that could be linked to an element, search hits.
abstract interface class TextOverlaySource {
  List<TextOverlay> overlays(BuildContext context);
}

/// Quill's `textSpanBuilder` for several overlay sources at once. The text of
/// each leaf is cut wherever an overlay starts or ends, and every piece gets
/// the styles of the overlays covering it; later sources win a conflict.
InlineSpan layeredSpan(
  BuildContext context,
  Node node,
  int nodeOffset,
  String text,
  TextStyle? style,
  GestureRecognizer? recognizer,
  List<TextOverlaySource> sources,
) {
  final from = node.documentOffset + nodeOffset;
  final to = from + text.length;
  final mouseCursor = recognizer != null ? SystemMouseCursors.click : null;
  TextSpan plain(
    String value,
    TextStyle? s, {
    void Function(PointerEnterEvent event)? onEnter,
    void Function(PointerExitEvent event)? onExit,
  }) => TextSpan(
    text: value,
    style: s,
    recognizer: recognizer,
    mouseCursor: mouseCursor,
    onEnter: onEnter,
    onExit: onExit,
  );
  if (text.isEmpty) return plain(text, style);
  final overlays = [
    for (final source in sources)
      for (final overlay in source.overlays(context))
        if (overlay.end > from && overlay.start < to) overlay,
  ];
  if (overlays.isEmpty) return plain(text, style);
  final cuts = <int>{from, to};
  for (final overlay in overlays) {
    cuts
      ..add(overlay.start.clamp(from, to))
      ..add(overlay.end.clamp(from, to));
  }
  final points = cuts.toList()..sort();
  final children = <TextSpan>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    var piece = style;
    void Function(PointerEnterEvent event)? onEnter;
    void Function(PointerExitEvent event)? onExit;
    for (final overlay in overlays) {
      if (overlay.start <= a && overlay.end >= b) {
        piece = (piece ?? const TextStyle()).merge(overlay.style);
        onEnter = overlay.onEnter ?? onEnter;
        onExit = overlay.onExit ?? onExit;
      }
    }
    children.add(
      plain(
        text.substring(a - from, b - from),
        piece,
        onEnter: onEnter,
        onExit: onExit,
      ),
    );
  }
  return TextSpan(children: children, style: style);
}
