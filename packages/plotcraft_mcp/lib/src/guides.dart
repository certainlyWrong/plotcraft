/// Text the AI can read to learn how Plotcraft is organised.

const dataModelGuide = '''
# Plotcraft data model

A **project** is a folder: identity (title, subtitle, author, genre, tags,
description, cover), a **manuscript**, **elements**, a **gallery** and optional
**fonts**. `format` is `book` (has a manuscript) or `manga` (elements and
gallery only).

## Manuscript
A book is an ordered list of **chapters** (always at least one). Each chapter
is a rich text document. Read and write it as Markdown; colors, fonts and sizes
exist only in the rich format and are applied with `edit_chapter`
(`format_text`), which also sets the line formats of the editor (`header`,
`list`, `quote`, `indent`, `align`); `clear_format` removes formatting.
The MCP always works with chapters: a project saved as one manuscript becomes
a single chapter the first time it is opened here.
Every read returns a `revision`; send it back as `base_revision` when writing
so you never overwrite what the author typed meanwhile. A `conflict` error
means: read again and redo the change.

## Elements
An element is a character, place, object, creature, organization, event,
concept, note, or an item of a custom type. It has:

- `title`, `summary`, `aliases` (other names, also detected in the text),
  `tags`, an optional `icon` and `color`;
- `fields`: the details of its type, by field id (see `list_element_types`);
  a detail of kind `element`/`elements` points to other elements (the "where" of
  an event takes place ids): send ids, or titles, which are stored as ids;
- `sections`: free-form titled Markdown notes;
- `phases`: how it changes through the story. A phase can be anchored to the
  chapter where it starts; `get_active_phase` tells which one is in force in a
  chapter. A phase can override some details (`field_overrides`);
- `relations`: directed links to other elements with a `label` ("sister of")
  and a `reciprocal_label`; the other element sees them too;
- `images`: gallery image ids, the first is the cover;
- `time`: when it happens in the story, `{"label": "Year 312", "position":
  312}`. The label is free text (any calendar, or none); the number only orders
  things on the timeline. Events fill it in most often, but any element can;
- `mention_policy`: whether its name and aliases are highlighted in the text.

## Mentions
Write `[[element:<element id>|Name]]` in Markdown to link text to an element.
`link_mentions` links names already written in plain text.

## Gallery
Images live in the project gallery and are referenced by id: in elements
(`images`) and in chapters (`![](gallery://<id>)`).
''';

const markdownGuide = '''
# Markdown in Plotcraft chapters

Standard Markdown (headings, **bold**, *italic*, lists, quotes, links) plus:

- `[[element:maria|Maria]]` — a link to the element with id `maria`; the text
  shown is the name after the bar.
- `![](gallery://g_abc123)` — shows the gallery image with that id.
- `---` — a horizontal divider.
- `<u>underlined</u>` — underline.

Not representable in Markdown: colors, fonts, sizes, alignment. Use
`edit_chapter` with `format_text` for those. The Markdown you read back from `get_chapter` omits
them, so do not rewrite a chapter you formatted with `write_chapter`
(replace); use `edit_chapter` operations instead.
''';
