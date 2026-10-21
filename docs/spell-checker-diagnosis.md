**English** · [Português](pt-BR/spell-checker-diagnosis.md) · [Español](es/spell-checker-diagnosis.md)

# Spell checker diagnosis

The checker uses macOS's `NSSpellChecker` (`macos/Runner/MainFlutterWindow.swift`) through
`lib/core/spellcheck/`. If a suggestion from the context menu is not applied, run the app in debug
mode and read the console:

```sh
flutter run -d macos
```

Lines that start with `[spell]`:

| Line | Means |
| --- | --- |
| `menu opened: selection …, target "word" Misspelling(a, b)` | The right click found a misspelled word (or `target none`: none). |
| `suggestions for "word": [...]` | macOS returned these suggestions. |
| `menu item pressed` | The click reached the menu item. |
| `replaced "word" at a-b with "x"; text changed: true` | The chapter's text was replaced. |
| `"word" is no longer in the text` | The word changed between opening the menu and clicking. |

If `menu item pressed` does not appear, the click is not reaching the menu; if it appears without
`replaced`, the text changed before the click.

## Tests that use the real checker

```sh
flutter test integration_test/spellcheck_test.dart -d macos            # simple editor and BookEditor
flutter test integration_test/workspace_spellcheck_test.dart -d macos  # full workspace and writing to disk
```
