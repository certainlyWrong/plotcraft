[English](../spell-checker.md) · [Português](../pt-BR/spell-checker.md) · **Español**

# Corrector ortográfico en el editor enriquecido

Resultado de la prueba de viabilidad hecha antes de adoptar `flutter_quill`: **es viable**, con el corrector del propio sistema.

## El problema
`flutter_quill` dibuja el texto por su cuenta y no usa el `SpellCheckService` de Flutter, que es el que usa `TextField`. Por tanto, el corrector del sistema tiene que conectarse a Quill por otro camino.

## Qué se verificó
- **Gancho de dibujo.** Quill acepta un `textSpanBuilder` en `QuillEditorConfig`. Recibe cada fragmento de texto junto con su desplazamiento en el documento (`node.documentOffset + nodeOffset`), de modo que se puede dividir el fragmento en las palabras erróneas y subrayarlas con una línea ondulada. Es solo pintura: no se escribe nada en el documento, así que el Delta guardado y el historial de deshacer quedan limpios (una prueba comprueba que el Delta no contiene `underline` ni `wavy`).
- **Menú de sugerencias.** `contextMenuBuilder` recibe el estado del editor, que expone `contextMenuButtonItems` y `contextMenuAnchors`. Se mantiene el menú normal y las sugerencias se colocan delante.
- **Posición de los subrayados al escribir.** Los intervalos siguen cada edición (`Delta.transformPosition`), así que el subrayado se queda en la palabra hasta la siguiente comprobación. Las respuestas de comprobaciones antiguas se descartan.
- **Deshacer.** Cambiar una palabra por una sugerencia es una única edición de Quill. Una nota para las pruebas y para la carga: el documento debe crearse a partir del JSON guardado (`Document.fromJson`). Un documento armado con `insert` después de creado hace que el primer "deshacer" vuelva al texto vacío.

## Código nativo (macOS)
Mediciones con `NSSpellChecker` en un texto de 10.000 palabras (1.100 errores):

| Forma | Tiempo |
|---|---|
| `checkSpelling` en un bucle, solo los intervalos | 439 ms |
| `checkSpelling` en un bucle, con sugerencias para 300 errores | 3,8 s |
| `requestChecking` asíncrono, texto completo | 91 ms |
| `requestChecking`, un párrafo de 400 caracteres | 2,6 ms |
| sugerencias para una palabra | 16 ms |

Decisiones que se derivan de esto:
- La comprobación usa `requestChecking` (asíncrono, sin límite de errores) y devuelve **solo los intervalos**.
- Las sugerencias vienen de una llamada aparte (`suggest`), hecha **bajo demanda**, cuando la persona abre el menú sobre una palabra.
- Con la identificación automática del idioma activada, se ignoraba el idioma pedido. Se desactiva en cada llamada.
- `learn` añade una palabra al diccionario del usuario.

Medido en la aplicación macOS real (`tool/spellcheck_probe.dart`): un texto de 66.000 caracteres con 4.000 errores en unos 120 ms por el canal; en `pt-BR` solo se marcan los errores reales, y en `en` también se marcan las palabras en portugués.

## Rendimiento en Dart
Un capítulo de 10.000 palabras con 1.428 errores (prueba de widget en modo debug, más lento que la aplicación): primera pintura con subrayados 129 ms, y una tecla pulsada se repinta en 31 ms. Quill monta todos los párrafos del documento, así que el coste crece con el tamaño del capítulo.

## Estructura
- `lib/core/spellcheck/spell_check_backend.dart`: el contrato (`check`, `suggest`, `learn`) y la implementación por canal de macOS.
- `lib/core/spellcheck/quill_spell_checker.dart`: conecta un `QuillController` con el corrector, mantiene los intervalos y ofrece `spanBuilder` y `buildContextMenu`.
- `macos/Runner/MainFlutterWindow.swift`: los métodos `checkRanges`, `suggest` y `learn`.
- `tool/spellcheck_probe.dart`: ejecuta el corrector nativo una vez e imprime el resultado (`flutter run -d macos -t tool/spellcheck_probe.dart`).

## Aún por hacer
- Windows (`ISpellChecker`) y Linux (enchant o hunspell) necesitan implementaciones del mismo contrato; sin ellas el editor funciona, solo que sin subrayados.
- Comprobación incremental por párrafo: hoy se comprueba todo el texto tras una pausa al escribir, lo que es lo bastante rápido para capítulos normales.
- Conectar el corrector al editor del workspace (ocurre cuando Quill sustituya al editor de Markdown).
