import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter's default spell checker has no desktop backend. On macOS this
/// adapter asks NSSpellChecker for ranges and replacement suggestions.
class NativeSpellCheckService implements SpellCheckService {
  const NativeSpellCheckService();

  static const _channel = MethodChannel('plotcraft/spell_check');
  static Timer? _debounce;
  static Completer<List<SuggestionSpan>?>? _pending;
  static int _generation = 0;

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    _generation++;
    final request = _generation;
    _debounce?.cancel();
    if (_pending != null && !_pending!.isCompleted) _pending!.complete(null);
    if (!Platform.isMacOS || text.isEmpty) return const [];
    final completer = Completer<List<SuggestionSpan>?>();
    _pending = completer;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
          'check',
          {'text': text, 'locale': locale.toLanguageTag()},
        );
        final spans = (result ?? const []).map((entry) {
          final start = entry['start'] as int;
          final end = entry['end'] as int;
          final suggestions =
              (entry['suggestions'] as List<dynamic>? ?? const [])
                  .whereType<String>()
                  .toList();
          return SuggestionSpan(TextRange(start: start, end: end), suggestions);
        }).toList();
        if (request == _generation && !completer.isCompleted) {
          completer.complete(spans);
        }
      } catch (_) {
        if (request == _generation && !completer.isCompleted) {
          completer.complete(null);
        }
      }
    });
    return completer.future;
  }
}
