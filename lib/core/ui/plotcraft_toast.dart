import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

/// Shows short messages, set on a small sheet of paper with a dot of ink in
/// place of the dark pill of a stock snack bar.
///
/// It reads everything it needs from the context when it is created, so create
/// it *before* an `await` and use it afterwards: the screen may be gone by then,
/// and the message must still be shown without touching a dead context.
class PlotcraftToaster {
  PlotcraftToaster.of(BuildContext context)
    : _messenger = ScaffoldMessenger.of(context),
      _theme = Theme.of(context),
      _ink = context.tokens.ink;

  final ScaffoldMessengerState _messenger;
  final ThemeData _theme;
  final Color _ink;

  SnackBar snackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final scheme = _theme.colorScheme;
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 440,
      duration: duration,
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      action: action,
      content: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: _theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows [message], replacing the one on screen.
  void show(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar(message, duration: duration, action: action));
  }

  void hide() => _messenger.hideCurrentSnackBar();
}

/// A toast as a [SnackBar], for a place that is still in the tree:
/// `ScaffoldMessenger.of(context).showSnackBar(plotcraftToast(context, text))`.
/// After an `await`, use a [PlotcraftToaster] created before it.
SnackBar plotcraftToast(BuildContext context, String message) =>
    PlotcraftToaster.of(context).snackBar(message);
