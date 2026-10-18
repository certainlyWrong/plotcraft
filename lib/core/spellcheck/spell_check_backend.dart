import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

/// A misspelled stretch of text, as UTF-16 offsets into the checked string.
class Misspelling {
  const Misspelling(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is Misspelling && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Misspelling($start, $end)';
}

/// The operating system's spell checker. Suggestions are a separate call
/// because producing them is slow compared with finding the errors.
abstract interface class SpellCheckBackend {
  /// Misspelled ranges of [text]; empty when the language is not available.
  Future<List<Misspelling>> check(String text, Locale locale);

  Future<List<String>> suggest(String word, Locale locale);

  /// Adds [word] to the user's dictionary.
  Future<void> learn(String word);
}

/// Spell checking through the macOS `NSSpellChecker` (see
/// `macos/Runner/MainFlutterWindow.swift`).
class MethodChannelSpellCheckBackend implements SpellCheckBackend {
  const MethodChannelSpellCheckBackend();

  static const _channel = MethodChannel('plotcraft/spell_check');

  /// True where a native checker is wired up.
  static bool get isSupported => Platform.isMacOS;

  @override
  Future<List<Misspelling>> check(String text, Locale locale) async {
    if (!isSupported || text.isEmpty) return const [];
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'checkRanges',
      {'text': text, 'locale': locale.toLanguageTag()},
    );
    return [
      for (final entry in result ?? const <Map<Object?, Object?>>[])
        if (entry['start'] is int && entry['end'] is int)
          Misspelling(entry['start']! as int, entry['end']! as int),
    ];
  }

  @override
  Future<List<String>> suggest(String word, Locale locale) async {
    if (!isSupported || word.isEmpty) return const [];
    final result = await _channel.invokeListMethod<String>('suggest', {
      'word': word,
      'locale': locale.toLanguageTag(),
    });
    return result ?? const [];
  }

  @override
  Future<void> learn(String word) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('learn', {'word': word});
  }
}
