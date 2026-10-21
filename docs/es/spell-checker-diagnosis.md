[English](../spell-checker-diagnosis.md) · [Português](../pt-BR/spell-checker-diagnosis.md) · **Español**

# Diagnóstico del corrector ortográfico

El corrector usa el `NSSpellChecker` de macOS (`macos/Runner/MainFlutterWindow.swift`) a través de
`lib/core/spellcheck/`. Si una sugerencia del menú contextual no se aplica, ejecute la aplicación en modo
debug y lea la consola:

```sh
flutter run -d macos
```

Líneas que empiezan por `[spell]`:

| Línea | Significa |
| --- | --- |
| `menu opened: selection …, target "palabra" Misspelling(a, b)` | El clic derecho encontró una palabra errónea (o `target none`: ninguna). |
| `suggestions for "palabra": [...]` | macOS devolvió estas sugerencias. |
| `menu item pressed` | El clic llegó al elemento del menú. |
| `replaced "palabra" at a-b with "x"; text changed: true` | Se cambió el texto del capítulo. |
| `"palabra" is no longer in the text` | La palabra cambió entre abrir el menú y hacer clic. |

Si no aparece `menu item pressed`, el clic no está llegando al menú; si aparece sin
`replaced`, el texto cambió antes del clic.

## Pruebas que usan el corrector real

```sh
flutter test integration_test/spellcheck_test.dart -d macos            # editor simple y BookEditor
flutter test integration_test/workspace_spellcheck_test.dart -d macos  # workspace completo y escritura en disco
```
