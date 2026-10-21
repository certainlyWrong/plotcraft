**English** · [Português](pt-BR/spell-checker.md) · [Español](es/spell-checker.md)

# Spell checker in the rich editor

Result of the feasibility test done before adopting `flutter_quill`: **it is feasible**, using the system's own spell checker.

## The problem
`flutter_quill` draws the text on its own and does not use Flutter's `SpellCheckService`, which is what `TextField` uses. The system spell checker therefore has to be connected to Quill another way.

## What was verified
- **Drawing hook.** Quill accepts a `textSpanBuilder` in `QuillEditorConfig`. It receives each piece of text together with the offset in the document (`node.documentOffset + nodeOffset`), so the piece can be split at the misspelled words and underlined with a wavy line. It is painting only: nothing is written to the document, so the saved Delta and the undo history stay clean (a test checks that the Delta contains neither `underline` nor `wavy`).
- **Suggestions menu.** `contextMenuBuilder` receives the editor's state, which exposes `contextMenuButtonItems` and `contextMenuAnchors`. The normal menu is kept and the suggestions go in front.
- **Underline position while typing.** The ranges follow each edit (`Delta.transformPosition`), so the underline stays on the word until the next check. Answers from old checks are discarded.
- **Undo.** Replacing a word with a suggestion is a single Quill edit. A note for tests and for loading: the document must be created from the saved JSON (`Document.fromJson`). A document built with `insert` after it was created makes the first "undo" go back to the empty text.

## Native code (macOS)
Measurements with `NSSpellChecker` on a 10,000-word text (1,100 errors):

| Approach | Time |
|---|---|
| `checkSpelling` in a loop, ranges only | 439 ms |
| `checkSpelling` in a loop, with suggestions for 300 errors | 3.8 s |
| asynchronous `requestChecking`, whole text | 91 ms |
| `requestChecking`, one 400-character paragraph | 2.6 ms |
| suggestions for one word | 16 ms |

Decisions that follow from this:
- Checking uses `requestChecking` (asynchronous, with no limit on errors) and returns **only the ranges**.
- Suggestions come from a separate call (`suggest`), made **on demand**, when the person opens the menu over a word.
- With automatic language identification on, the requested language was ignored. It is turned off on every call.
- `learn` adds a word to the user's dictionary.

Measured in the real macOS app (`tool/spellcheck_probe.dart`): a 66,000-character text with 4,000 errors in about 120 ms over the channel; in `pt-BR` only the real errors are marked, and in `en` the Portuguese words are marked too.

## Performance in Dart
A 10,000-word chapter with 1,428 errors (widget test in debug mode, slower than the app): first paint with underlines 129 ms, and a typed key repaints in 31 ms. Quill builds every paragraph of the document, so the cost grows with the size of the chapter.

## Structure
- `lib/core/spellcheck/spell_check_backend.dart`: the contract (`check`, `suggest`, `learn`) and the macOS channel implementation.
- `lib/core/spellcheck/quill_spell_checker.dart`: connects a `QuillController` to the checker, keeps the ranges and provides `spanBuilder` and `buildContextMenu`.
- `macos/Runner/MainFlutterWindow.swift`: the `checkRanges`, `suggest` and `learn` methods.
- `tool/spellcheck_probe.dart`: runs the native checker once and prints the result (`flutter run -d macos -t tool/spellcheck_probe.dart`).

## Not done yet
- Windows (`ISpellChecker`) and Linux (enchant or hunspell) need implementations of the same contract; without them the editor works, just without underlines.
- Incremental checking by paragraph: today the whole text is checked after a pause in typing, which is fast enough for normal chapters.
- Connecting the checker to the workspace editor (it happens when Quill replaces the Markdown editor).
