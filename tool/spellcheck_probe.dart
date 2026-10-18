// Runs the native spell checker once and prints the result, then exits.
//   flutter run -d macos -t tool/spellcheck_probe.dart
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:plotcraft/core/spellcheck/spell_check_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const backend = MethodChannelSpellCheckBackend();
  const text = 'A corredora chegou na pasagem errro do vento. Pista de sal.';
  for (final locale in const [Locale('pt', 'BR'), Locale('en')]) {
    final clock = Stopwatch()..start();
    final found = await backend.check(text, locale);
    clock.stop();
    stdout.writeln(
      'PROBE ${locale.toLanguageTag()} ${clock.elapsedMilliseconds}ms '
      '${found.map((m) => '"${text.substring(m.start, m.end)}"@${m.start}-${m.end}').toList()}',
    );
    if (found.isNotEmpty) {
      final word = text.substring(found.first.start, found.first.end);
      stdout.writeln(
        'PROBE suggest($word) = ${await backend.suggest(word, locale)}',
      );
    }
  }
  // A long text, to confirm the call stays asynchronous and fast.
  final long = List.filled(2000, 'a corredora chegou errro pasagem').join(' ');
  final clock = Stopwatch()..start();
  final many = await backend.check(long, const Locale('pt', 'BR'));
  stdout.writeln(
    'PROBE long chars=${long.length} found=${many.length} ${clock.elapsedMilliseconds}ms',
  );
  stdout.writeln('PROBE done');
  exit(0);
}
