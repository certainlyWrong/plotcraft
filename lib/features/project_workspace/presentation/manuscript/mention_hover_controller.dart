import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a card near the pointer after it rests on a mention for [delay], and
/// removes it when the pointer leaves, the text scrolls or changes.
class MentionHoverController {
  MentionHoverController({
    required this.context,
    required this.cardFor,
    this.delay = const Duration(milliseconds: 400),
  });

  /// A context under the app's Overlay and theme.
  final BuildContext Function() context;

  /// The card for an element ID; null shows nothing.
  final Widget? Function(String elementId) cardFor;
  final Duration delay;

  static const _cardWidth = 320.0;
  static const _cardHeight = 360.0;

  Timer? _timer;
  OverlayEntry? _entry;
  String? _shownId;

  bool get isShowing => _entry != null;

  /// The pointer entered a mention of [elementId] at global [position].
  void enter(String elementId, Offset position) {
    if (_shownId == elementId && _entry != null) {
      _timer?.cancel();
      return;
    }
    hide();
    _timer = Timer(delay, () => _show(elementId, position));
  }

  void leave() => hide();

  void _show(String elementId, Offset position) {
    final host = context();
    if (!host.mounted) return;
    final card = cardFor(elementId);
    if (card == null) return;
    final screen = MediaQuery.sizeOf(host);
    var left = position.dx + 12;
    if (left + _cardWidth > screen.width - 12) {
      left = (position.dx - _cardWidth - 12).clamp(12, screen.width);
    }
    var top = position.dy + 20;
    final above = top + _cardHeight > screen.height - 12;
    if (above) top = position.dy - 12;
    _shownId = elementId;
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: above ? null : top,
        bottom: above ? screen.height - top : null,
        child: IgnorePointer(child: card),
      ),
    );
    Overlay.of(host).insert(_entry!);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _shownId = null;
  }

  void dispose() => hide();
}
