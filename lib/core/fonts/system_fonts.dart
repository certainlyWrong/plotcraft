import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// The font families installed on this computer.
abstract interface class SystemFontLister {
  Future<List<String>> families();
}

/// Asks the operating system. macOS answers through `NSFontManager`; Linux
/// uses `fc-list` and Windows reads the font registry. A computer where the
/// list cannot be read simply gets no system fonts in the menu.
class PlatformSystemFontLister implements SystemFontLister {
  const PlatformSystemFontLister();

  static const _channel = MethodChannel('plotcraft/fonts');
  static List<String>? _cache;

  @override
  Future<List<String>> families() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final found = Platform.isMacOS
          ? await _macOs()
          : Platform.isLinux
          ? await _linux()
          : Platform.isWindows
          ? await _windows()
          : const <String>[];
      return _cache = normalizeFamilies(found);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _macOs() async =>
      await _channel.invokeListMethod<String>('families') ?? const [];

  Future<List<String>> _linux() async {
    final result = await Process.run('fc-list', const [':', 'family']);
    if (result.exitCode != 0) return const [];
    return const LineSplitter().convert(result.stdout as String);
  }

  Future<List<String>> _windows() async {
    final result = await Process.run('reg', const [
      'query',
      r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
    ]);
    if (result.exitCode != 0) return const [];
    return parseWindowsFontRegistry(result.stdout as String);
  }
}

/// Sorted, de-duplicated family names. Names that fontconfig lists with
/// alternatives ("Noto Sans,Noto Sans Regular") keep the first one, and
/// internal families (starting with a dot) are dropped.
List<String> normalizeFamilies(Iterable<String> raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final entry in raw) {
    final name = entry.split(',').first.trim();
    if (name.isEmpty || name.startsWith('.')) continue;
    if (seen.add(name.toLowerCase())) result.add(name);
  }
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

/// Family names from the output of `reg query ...\Fonts`. Entries look like
/// `Arial Bold Italic (TrueType)    REG_SZ    arialbi.ttf`; the style words
/// and the format are removed so each family appears once.
List<String> parseWindowsFontRegistry(String output) {
  final families = <String>[];
  for (final line in const LineSplitter().convert(output)) {
    final match = RegExp(r'^\s+(.+?)\s+REG_\w+\s+').firstMatch(line);
    if (match == null) continue;
    var name = match
        .group(1)!
        .replaceAll(RegExp(r'\s*\((TrueType|OpenType)\)'), '');
    // "Cambria & Cambria Math" lists two fonts of one file; keep the first.
    name = name.split(' & ').first;
    name = name.replaceAll(
      RegExp(
        r'\s+(Regular|Bold|Italic|Oblique|Light|Semibold|SemiBold|Black|Medium|Thin|Narrow|Condensed)(\s+(Italic|Oblique))?$',
        caseSensitive: false,
      ),
      '',
    );
    if (name.trim().isNotEmpty) families.add(name.trim());
  }
  return families;
}
