[English](README.md) · [Português](README.pt-BR.md) · **Español**

# Servidor MCP de Plotcraft

Un servidor [MCP](https://modelcontextprotocol.io) que permite a un asistente de IA leer y
escribir historias de [Plotcraft](../../README.es.md): crear proyectos, escribir y editar
capítulos, construir personajes, lugares y otros **elementos** de la historia (con fases,
relaciones e imágenes), gestionar la galería y las fuentes, e incluso controlar la
aplicación en ejecución (tema, idioma, abrir pantallas, corrección ortográfica).

Habla por **stdio**, trabaja directamente sobre las carpetas de los proyectos (la aplicación
no necesita estar abierta) y protege a quien escribe:

- toda escritura se comprueba contra una **revisión**, así que la IA nunca sobrescribe lo
  que usted escribió entretanto (la aplicación, a su vez, recarga lo que la IA cambió y le
  pregunta cuando ambos tocaron el mismo capítulo);
- todo lo que destruye datos exige **confirmación explícita**
  (`confirm: true` más el nombre exacto del elemento);
- quitar un capítulo o un elemento lo **archiva** en lugar de borrarlo;
- `--read-only` desactiva toda herramienta que cambie algo.

> Los nombres y las descripciones de las herramientas, los códigos de error y los mensajes del
> servidor están en inglés, tal como los informa el servidor. El catálogo de abajo se mantiene
> en inglés.

## Instalación

```sh
tool/build_mcp.sh            # desde la raíz del repositorio; escribe build/plotcraft-mcp
```

(o ejecútelo desde el código con `dart run packages/plotcraft_mcp/bin/plotcraft_mcp.dart`.)

### Claude Code

```sh
claude mcp add plotcraft -- /ruta/a/plotcraft-mcp --root ~/Documents/plotcraft
```

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "plotcraft": {
      "command": "/ruta/a/plotcraft-mcp",
      "args": ["--root", "/Users/usted/Documents/plotcraft"]
    }
  }
}
```

### Opciones

| Opción | Significado |
| --- | --- |
| `--root <carpeta>` (o `PLOTCRAFT_ROOT`) | La carpeta de proyectos de Plotcraft: cada subcarpeta con un `project.json` es un proyecto. Use la misma carpeta que usa la aplicación (Preferencias → Carpeta de proyectos). |
| `--project <carpeta>` | Una carpeta de proyecto adicional, fuera de `--root` (se puede repetir). |
| `--read-only` | Rechaza toda herramienta que cambie algo. |

## Cómo debe trabajar la IA

1. `list_projects` (o `create_project`) y, después, pase el **id**, la carpeta o el título
   exacto del proyecto a todas las demás herramientas.
2. Lea antes de escribir. `get_chapter` / `get_element` devuelven una `revision`;
   envíela de vuelta como `base_revision`. Un error `conflict` significa que el archivo cambió:
   léalo de nuevo y rehaga el cambio.
3. Escriba los capítulos en **Markdown**. Vincule un nombre a un elemento con
   `[[element:<id>|Nombre]]`, muestre una imagen de la galería con `![](gallery://<id>)`; un
   separador es `---`. Los colores, las fuentes y los tamaños existen solo en el formato
   enriquecido: use `edit_chapter` con `format_text`. La misma operación define los formatos de
   línea del editor (`header` 1-3, `list`, `quote`, `indent`, `align`) y `clear_format` quita el
   formato, así que todo lo que hace la barra de herramientas del editor con el texto se puede
   hacer desde aquí. Deshacer y rehacer son del editor: toda escritura es atómica y está
   protegida por `base_revision`, así que para rehacer un cambio lea el capítulo de nuevo.
4. Prefiera `edit_chapter` (ediciones precisas que conservan el formato y los enlaces) a
   reescribir un capítulo entero.

El servidor también publica **recursos** (`plotcraft://guide/data-model`,
`plotcraft://guide/markdown`, `plotcraft://projects` y una plantilla por proyecto, capítulo,
elemento e imagen de la galería) y **prompts** (`story_bible_from_premise`, `draft_chapter`,
`continuity_check`, `develop_character`, `revise_chapter`).

## Errores

Una llamada fallida devuelve `isError` con `{"error": {"code", "message", "hint"}}`.
Códigos: `notFound`, `conflict`, `validation`, `confirmationRequired`,
`readOnly`, `appNotRunning`, `unsupported`, `timeout`, `io`, `internal`.

## Herramientas

| Tool | What it does | Kind |
| --- | --- | --- |
| `get_server_info` | Describes this Plotcraft MCP server: version, the projects folder, whether it is read-only, and how many projects it sees. | read |
| `list_projects` | Lists the story projects the server can see, newest first. | read |
| `get_project` | Returns a project's identity and an overview: word count, chapters, elements and gallery images. | read |
| `create_project` | Creates a new story project (a folder) in the projects folder, with one empty chapter. | write |
| `update_project` | Changes the identity of a project. | write |
| `delete_project` | PERMANENTLY deletes a project folder with everything in it (manuscript, elements, gallery, fonts). | **destructive** (needs confirmation) |
| `list_chapters` | Lists the chapters of a book in reading order with word counts and revisions. | read |
| `get_chapter` | Reads a chapter. | read |
| `write_chapter` | Writes the text of a chapter. | write |
| `edit_chapter` | Applies precise edits to a chapter, in order, keeping the formatting around them. | write |
| `add_chapter` | Adds a chapter at the end (or at "position", counting from 0), optionally with its first text. | write |
| `rename_chapter` | Changes the title of a chapter. | write |
| `reorder_chapters` | Sets the reading order. | write |
| `remove_chapter` | Removes a chapter from the book. | **destructive** (needs confirmation) |
| `search_manuscript` | Finds text in every chapter (or in "chapter_ids"). | read |
| `replace_in_manuscript` | Replaces text in every chapter (or in "chapter_ids"), keeping formatting. | write |
| `link_mentions` | Turns the plain-text names and aliases of elements that are written in the chapters into links to those elements (the text does not change). | write |
| `get_manuscript_stats` | Word counts per chapter and in total, with an estimated reading time (220 words per minute). | read |
| `list_elements` | Lists the story elements (characters, places, objects...) of a project, sorted by title. | read |
| `get_element` | Returns everything about an element: details, sections, phases, relations (also the ones other elements have to it), images and its revision. | read |
| `create_element` | Creates a story element. | write |
| `update_element` | Changes an element. | write |
| `delete_element` | Removes an element: its file is archived in the project's content/narrative/archive folder (recoverable by hand), relations other elements had to it are dropped, and links in the text keep their names but point nowhere. | **destructive** (needs confirmation) |
| `add_relation` | Links an element to another: "label" is what this element is to the other ("sister of"); "reciprocal_label" what the other is to this one (defaults to the same label). | write |
| `update_relation` | Changes the label, reciprocal label, note or target of a relation. | write |
| `remove_relation` | Removes one relation from an element. | write |
| `add_phase` | Adds a phase: a moment in the element's life, optionally anchored to the chapter where it starts, with details that change then. | write |
| `update_phase` | Changes a phase. | write |
| `remove_phase` | Removes one phase from an element. | write |
| `add_section` | Adds a free-form note to an element (a titled block of Markdown), for backstory, rules, lore or research. | write |
| `update_section` | Changes the title or text of a section. | write |
| `remove_section` | Removes one section from an element. | write |
| `set_element_images` | Sets the images of an element; the first is its cover. | write |
| `set_mention_policy` | "auto": whether the element's name and aliases are highlighted in the manuscript; "ignored_terms": names or aliases not to detect (for example a common word that is also a name). | write |
| `get_element_references` | Lists where the element's name or aliases are written in the manuscript, and whether each one is linked to the element. | read |
| `get_active_phase` | Says which phase of the element is in force while reading a chapter (the latest one anchored at or before it), or null. | read |
| `export_book` | Saves the manuscript as an EPUB (for Kindle and other e-readers), a PDF or a single HTML file. | write |
| `list_element_types` | Lists the types an element can have: the built-in ones (character, place, object, creature, organization, event, concept, note) and the project's own, each with the details (fields) its elements have. | read |
| `create_element_type` | Creates a custom element type (for example "Spell" or "Faction") with its own icon, color and details. | write |
| `update_element_type` | Changes a custom type. | write |
| `delete_element_type` | Deletes a custom type. | **destructive** (needs confirmation) |
| `list_icon_sets` | Lists the icon sets elements and types can use. | read |
| `search_icons` | Finds icons by name words (e.g. | read |
| `list_suggested_icons` | Hand-picked icons for stories, in groups: people, places, objects, creatures, organizations, magic, events and notes. | read |
| `list_gallery` | Lists the images of the project gallery. | read |
| `get_gallery_image` | Returns a gallery image so you can look at it (up to 8 MB). | read |
| `import_gallery_images` | Copies image files (png, jpg, jpeg, webp, gif) from the computer into the project gallery. | write |
| `import_gallery_image_data` | Saves an image given as base64 (for example one you generated) in the gallery under "file_name" (png, jpg, jpeg, webp or gif). | write |
| `remove_gallery_image` | PERMANENTLY deletes an image file from the gallery. | **destructive** (needs confirmation) |
| `list_project_fonts` | Lists the font files stored in the project (they travel with it and can be used in the text). | read |
| `add_project_fonts` | Copies font files (ttf, otf, ttc; up to 30 MB each) into the project. | write |
| `remove_project_font` | PERMANENTLY deletes a font file from the project. | **destructive** (needs confirmation) |
| `get_app_status` | Says whether the Plotcraft app is open (with the same projects folder) and, if so, its version, theme, language and open project. | read |
| `get_preferences` | Reads the app's preferences: theme, interface font, language and projects folder, with the options for each. | read |
| `list_themes` | Lists the color themes of the app. | read |
| `set_theme` | Changes the app's color theme (see list_themes for the ids). | write |
| `set_interface_font` | Changes the font of the app's interface (see get_preferences for the options). | write |
| `set_language` | Changes the app's language ("en" or "pt"). | write |
| `set_projects_root` | Changes where new projects are created. | write |
| `open_in_app` | Opens a project in the running app and, optionally, a chapter (selecting the text range start..end in it) or an element, so the author sees what you are talking about. | read |
| `spell_check_text` | Checks spelling with the operating system's checker (the one the editor uses) and returns the misspelled ranges with suggestions. | read |
| `suggest_spelling` | Suggests corrections for one word. | read |
| `learn_word` | Adds a word to the user's dictionary so it is no longer flagged (for example a character name). | write |

### Herramientas que necesitan la aplicación abierta

`get_preferences`, `list_themes`, `set_theme`, `set_interface_font`,
`set_language`, `set_projects_root`, `open_in_app`, `spell_check_text`,
`suggest_spelling` y `learn_word` consultan la aplicación Plotcraft en ejecución (mediante
pequeños archivos de petición en `<carpeta de proyectos>/.plotcraft/`). Sin la aplicación,
responden `appNotRunning`. `get_app_status` indica si está abierta. La corrección ortográfica
usa el corrector del sistema operativo (hoy, el de macOS).

## Ejemplo

> "Crea una novela de misterio llamada *El Camino de la Sal*, con tres personajes y un
> primer capítulo."

El asistente llama a `create_project`, luego a `create_element` para cada personaje (creando
primero aquellos con los que se relacionan los demás), `add_relation`, `write_chapter` con un
Markdown que vincula a los personajes, y `link_mentions` para cualquier nombre que haya dejado
sin vincular. Mientras trabaja, la aplicación se actualiza sola.

## Desarrollo

```sh
cd packages/plotcraft_mcp
dart pub get
dart test                 # cliente en memoria para cada herramienta + una ejecución completa por stdio
dart run tool/print_catalog.dart   # la tabla de arriba
```

Los archivos del proyecto y lo que hace el servidor con ellos se describen en
[`docs/es/project-model.md`](../../docs/es/project-model.md) y
[`docs/es/mcp.md`](../../docs/es/mcp.md).
