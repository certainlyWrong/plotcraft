**English** · [Português](pt-BR/mcp.md) · [Español](es/mcp.md)

# MCP: an AI that creates and manages stories

Plotcraft has an [MCP](https://modelcontextprotocol.io) server that lets an AI (Claude Code, Claude Desktop and other clients) work on the same projects you open in the app. The server, its tools and its messages are in **English**. This page explains the design. The usage guide, with the full tool catalog, is in [`packages/plotcraft_mcp/README.md`](../packages/plotcraft_mcp/README.md).

## How the pieces fit together

```text
packages/
  plotcraft_core/   Pure Dart: models, Delta↔Markdown converters, repositories,
                    ProjectLibrary, StoryWorkspace and the bridge protocol
  plotcraft_mcp/    the stdio executable (tools, resources and prompts)
lib/                the Flutter app, which uses plotcraft_core
```

- **The server reads and writes the project folders** (the same format as the app, described in [Project model](project-model.md)). It does not need the app to be open.
- **`StoryWorkspace`** (in `plotcraft_core`) gathers the operations on a project without an interface: reading and writing chapters, elements, types, gallery and fonts. It is the base for the tools.
- **`BookAssembler` and `exportBook`** (in `plotcraft_core`, `features/export`) turn the manuscript Deltas into EPUB, PDF or HTML. The app and the `export_book` tool share them; the tool writes to `<project>/exports/` unless told otherwise.
- **`DeltaEdit`** edits rich text (replace, insert, format, link mentions, insert a divider or image) without an editor, keeping the formatting around the change.

## Content safety

- **Revisions.** Every read of a chapter or element returns a `revision` (a fingerprint of the file). A write over existing content sends it as `base_revision`; if the file changed in the meantime, the tool answers `conflict` and the AI reads again instead of overwriting.
- **Explicit confirmation.** Deleting a project, removing a chapter, element or type, and erasing an image or font require `confirm: true` and the target's exact name in `confirm_name`. Removing a chapter or element *archives* it (recoverable); deleting a project, a gallery image or a font is permanent.
- **Read only.** `--read-only` turns off every tool that changes something.
- **Audit.** Each write adds a line to `<project>/.plotcraft/mcp-log.jsonl` (long texts appear only by their length).

## The app follows the AI

While a project is open, the app watches its folder (`ProjectChangeWatcher`) and reloads whatever changed from outside:

- a chapter **with no changes of yours**: the text is updated right away, as a remote change (without going through the undo history);
- a chapter **with unsaved changes**: the app keeps your text, pauses that chapter's autosave and shows a banner — *Load the new one* or *Keep mine*;
- elements: the list is reloaded; an open editor with no changes is rebuilt, and one with changes shows the same banner;
- chapters created, renamed, reordered or removed appear in the list, and tabs of removed chapters close.

The library also watches the projects folder (`LibraryWatcher`): a project created by the AI shows up without reopening the app.

## Bridge with the app

Some things only the open app can do: change the theme, font or language, open a chapter or element on screen, and use the system spell checker. For that, the server and the app exchange files in `<projects folder>/.plotcraft/`:

| File | Written by | Purpose |
| --- | --- | --- |
| `app.json` | app (every 3 s) | heartbeat: version, theme, language, open project |
| `inbox/<id>.json` | server | a request (`method`, `params`) |
| `outbox/<id>.json` | app | the response (`ok`/`error`) |

Without the heartbeat (app closed, or open with another projects folder), those tools answer `appNotRunning`. The app does not switch project if the open one has unsaved changes.

## Tests

- `packages/plotcraft_core/test`: converters, `DeltaEdit`, `StoryWorkspace`, `ProjectLibrary`, bridge.
- `packages/plotcraft_mcp/test`: an in-memory MCP client calls **every** tool (success, validation, `conflict`, confirmation, read only) and a test starts the real executable over stdio.
- the app's `test/`: file watchers, chapter and element reload, conflict and the bridge.
