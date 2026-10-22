**English** · [Português](README.pt-BR.md) · [Español](README.es.md)

# Plotcraft MCP server

An [MCP](https://modelcontextprotocol.io) server that lets an AI assistant read
and write [Plotcraft](../../README.md) stories: create projects, write and edit
chapters, build characters, places and other story **elements** (with phases,
relations, images), manage the gallery and fonts, and even drive the running
app (theme, language, opening screens, spell checking).

It talks **stdio**, works on the project folders directly (the app does not
need to be open) and keeps the author safe:

- every write is checked against a **revision**, so the AI never overwrites
  something you typed meanwhile (the app, in turn, reloads what the AI
  changed, and asks you when both touched the same chapter);
- anything that destroys data needs **explicit confirmation**
  (`confirm: true` plus the exact name of the thing);
- removing a chapter or an element **archives** it instead of deleting;
- `--read-only` turns every changing tool off.

## Install

```sh
tool/build_mcp.sh            # from the repository root; writes build/plotcraft-mcp
```

(or run it from source with `dart run packages/plotcraft_mcp/bin/plotcraft_mcp.dart`.)

### Claude Code

```sh
claude mcp add plotcraft -- /path/to/plotcraft-mcp --root ~/Documents/plotcraft
```

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "plotcraft": {
      "command": "/path/to/plotcraft-mcp",
      "args": ["--root", "/Users/you/Documents/plotcraft"]
    }
  }
}
```

### Options

| Option | Meaning |
| --- | --- |
| `--root <dir>` (or `PLOTCRAFT_ROOT`) | The Plotcraft projects folder: each subfolder with a `project.json` is a project. Use the same folder the app uses (Preferences → Projects folder). |
| `--project <dir>` | An extra project folder outside `--root` (repeatable). |
| `--read-only` | Refuse every tool that changes something. |

## How the AI should work

1. `list_projects` (or `create_project`), then pass the project **id**,
   folder or exact title to every other tool.
2. Read before writing. `get_chapter` / `get_element` return a `revision`;
   send it back as `base_revision`. A `conflict` error means the file changed:
   read it again and redo the change.
3. Write chapters in **Markdown**. Link a name to an element with
   `[[element:<id>|Name]]`, show a gallery image with `![](gallery://<id>)`,
   a divider is `---`. Colors, fonts and sizes exist only in the rich format:
   use `edit_chapter` with `format_text`. The same operation sets the line
   formats of the editor (`header` 1-3, `list`, `quote`, `indent`, `align`) and
   `clear_format` removes formatting, so everything the editor's toolbar does
   to text can be done from here. Undo and redo are the editor's: every write
   is atomic and protected by `base_revision`, so redo a change by reading the
   chapter again.
4. Prefer `edit_chapter` (precise edits that keep formatting and links) over
   rewriting a whole chapter.

The server also publishes **resources** (`plotcraft://guide/data-model`,
`plotcraft://guide/markdown`, `plotcraft://projects`, and a template per
project, chapter, element and gallery image) and **prompts**
(`story_bible_from_premise`, `draft_chapter`, `continuity_check`,
`develop_character`, `revise_chapter`).

## Errors

A failed call returns `isError` with `{"error": {"code", "message", "hint"}}`.
Codes: `notFound`, `conflict`, `validation`, `confirmationRequired`,
`readOnly`, `appNotRunning`, `unsupported`, `timeout`, `io`, `internal`.

## Tools

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

### Tools that need the app running

`get_preferences`, `list_themes`, `set_theme`, `set_interface_font`,
`set_language`, `set_projects_root`, `open_in_app`, `spell_check_text`,
`suggest_spelling` and `learn_word` ask the running Plotcraft app (through
small request files in `<projects folder>/.plotcraft/`). Without the app they
answer `appNotRunning`. `get_app_status` tells whether it is open. Spell
checking uses the operating system's checker (macOS today).

## Example

> "Create a mystery novel called *The Salt Road* with three characters and a
> first chapter."

The assistant calls `create_project`, then `create_element` for each
character (creating the ones others relate to first), `add_relation`,
`write_chapter` with Markdown that links the characters, and `link_mentions`
for any name it left unlinked. While it works, the app updates by itself.

## Development

```sh
cd packages/plotcraft_mcp
dart pub get
dart test                 # in-memory client for every tool + an end-to-end run over stdio
dart run tool/print_catalog.dart   # the table above
```

Project files and what the server does with them are described in
[`docs/project-model.md`](../../docs/project-model.md) and
[`docs/mcp.md`](../../docs/mcp.md).
