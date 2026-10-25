[English](../mcp.md) · [Português](../pt-BR/mcp.md) · **Español**

# MCP: una IA que crea y gestiona historias

Plotcraft tiene un servidor [MCP](https://modelcontextprotocol.io) que permite a una IA (Claude Code, Claude Desktop y otros clientes) trabajar en los mismos proyectos que usted abre en la aplicación. El servidor, sus herramientas y sus mensajes están en **inglés**. Esta página explica el diseño. La guía de uso, con el catálogo completo de herramientas, está en [`packages/plotcraft_mcp/README.es.md`](../../packages/plotcraft_mcp/README.es.md).

## Cómo encajan las piezas

```text
packages/
  plotcraft_core/   Dart puro: modelos, conversores Delta↔Markdown, repositorios,
                    ProjectLibrary, StoryWorkspace y el protocolo del puente
  plotcraft_mcp/    el ejecutable stdio (herramientas, recursos y prompts)
lib/                la aplicación Flutter, que usa plotcraft_core
```

- **El servidor lee y escribe las carpetas de los proyectos** (el mismo formato que la aplicación, descrito en [Modelo de proyecto](project-model.md)). No necesita que la aplicación esté abierta.
- **`StoryWorkspace`** (en `plotcraft_core`) reúne las operaciones sobre un proyecto sin interfaz: leer y escribir capítulos, elementos, tipos, galería y fuentes. Es la base de las herramientas.
- **`BookAssembler` y `exportBook`** (en `plotcraft_core`, `features/export`) convierten los Deltas del manuscrito en EPUB, PDF o HTML. La app y la herramienta `export_book` los comparten; la herramienta escribe en `<proyecto>/exports/` salvo que se indique otra cosa.
- **`DeltaEdit`** edita el texto enriquecido (reemplazar, insertar, dar formato, vincular menciones, insertar un separador o una imagen) sin un editor, conservando el formato alrededor.

## Seguridad del contenido

- **Revisiones.** Toda lectura de un capítulo o elemento devuelve una `revision` (una huella del archivo). Una escritura sobre contenido existente la envía como `base_revision`; si el archivo cambió mientras tanto, la herramienta responde `conflict` y la IA lee de nuevo en vez de sobrescribir.
- **Confirmación explícita.** Eliminar un proyecto, quitar un capítulo, elemento o tipo, y borrar una imagen o fuente exigen `confirm: true` y el nombre exacto del objetivo en `confirm_name`. Quitar un capítulo o elemento lo *archiva* (recuperable); eliminar un proyecto, una imagen de la galería o una fuente es definitivo.
- **Solo lectura.** `--read-only` desactiva toda herramienta que cambie algo.
- **Auditoría.** Cada escritura añade una línea a `<proyecto>/.plotcraft/mcp-log.jsonl` (los textos largos aparecen solo por su tamaño).

## La aplicación acompaña a la IA

Mientras un proyecto está abierto, la aplicación observa su carpeta (`ProjectChangeWatcher`) y recarga lo que cambió desde fuera:

- un capítulo **sin cambios suyos**: el texto se actualiza al instante, como un cambio remoto (sin pasar por el historial de deshacer);
- un capítulo **con cambios sin guardar**: la aplicación conserva su texto, suspende el guardado automático de ese capítulo y muestra una franja — *Cargar el nuevo* o *Mantener el mío*;
- elementos: se recarga la lista; un editor abierto sin cambios se rehace, y uno con cambios muestra la misma franja;
- los capítulos creados, renombrados, reordenados o eliminados aparecen en la lista, y las pestañas de capítulos eliminados se cierran.

La biblioteca también observa la carpeta de proyectos (`LibraryWatcher`): un proyecto creado por la IA aparece sin reabrir la aplicación.

## Puente con la aplicación

Algunas cosas solo las sabe hacer la aplicación abierta: cambiar el tema, la fuente o el idioma, abrir un capítulo o elemento en pantalla y usar el corrector ortográfico del sistema. Para ello el servidor y la aplicación intercambian archivos en `<carpeta de proyectos>/.plotcraft/`:

| Archivo | Quién lo escribe | Para qué |
| --- | --- | --- |
| `app.json` | aplicación (cada 3 s) | latido: versión, tema, idioma, proyecto abierto |
| `inbox/<id>.json` | servidor | una petición (`method`, `params`) |
| `outbox/<id>.json` | aplicación | la respuesta (`ok`/`error`) |

Sin el latido (aplicación cerrada, o abierta con otra carpeta de proyectos), esas herramientas responden `appNotRunning`. La aplicación no cambia de proyecto si el abierto tiene cambios sin guardar.

## Pruebas

- `packages/plotcraft_core/test`: conversores, `DeltaEdit`, `StoryWorkspace`, `ProjectLibrary`, puente.
- `packages/plotcraft_mcp/test`: un cliente MCP en memoria llama a **cada** herramienta (éxito, validación, `conflict`, confirmación, solo lectura) y una prueba arranca el ejecutable real por stdio.
- el `test/` de la aplicación: observadores de archivos, recarga de capítulos y elementos, conflicto y el puente.
