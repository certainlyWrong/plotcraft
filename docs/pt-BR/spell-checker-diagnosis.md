[English](../spell-checker-diagnosis.md) · **Português** · [Español](../es/spell-checker-diagnosis.md)

# Diagnóstico do corretor ortográfico

O corretor usa o `NSSpellChecker` do macOS (`macos/Runner/MainFlutterWindow.swift`) através de
`lib/core/spellcheck/`. Se uma sugestão do menu de contexto não for aplicada, rode o app em modo
debug e leia o console:

```sh
flutter run -d macos
```

Linhas que começam com `[spell]`:

| Linha | Significa |
| --- | --- |
| `menu opened: selection …, target "palavra" Misspelling(a, b)` | O clique direito encontrou uma palavra errada (ou `target none`: nenhuma). |
| `suggestions for "palavra": [...]` | O macOS devolveu essas sugestões. |
| `menu item pressed` | O clique chegou ao item do menu. |
| `replaced "palavra" at a-b with "x"; text changed: true` | O texto do capítulo foi trocado. |
| `"palavra" is no longer in the text` | A palavra mudou entre abrir o menu e clicar. |

Se `menu item pressed` não aparecer, o clique não está chegando ao menu; se aparecer sem
`replaced`, o texto mudou antes do clique.

## Testes que usam o corretor real

```sh
flutter test integration_test/spellcheck_test.dart -d macos            # editor simples e BookEditor
flutter test integration_test/workspace_spellcheck_test.dart -d macos  # workspace completo e gravação em disco
```
