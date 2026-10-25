[English](README.md) · **Português** · [Español](README.es.md)

# Servidor MCP do Plotcraft

Um servidor [MCP](https://modelcontextprotocol.io) que deixa um assistente de IA ler e
escrever histórias do [Plotcraft](../../README.pt-BR.md): criar projetos, escrever e editar
capítulos, montar personagens, lugares e outros **elementos** da história (com fases,
relações e imagens), gerenciar a galeria e as fontes, e até controlar o aplicativo em
execução (tema, idioma, abrir telas, correção ortográfica).

Ele fala por **stdio**, trabalha diretamente nas pastas dos projetos (o aplicativo não
precisa estar aberto) e protege quem escreve:

- toda escrita é conferida com uma **revisão**, então a IA nunca sobrescreve o que você
  digitou nesse meio tempo (o aplicativo, por sua vez, recarrega o que a IA mudou e
  pergunta a você quando os dois mexeram no mesmo capítulo);
- tudo o que destrói dados exige **confirmação explícita**
  (`confirm: true` mais o nome exato do item);
- remover um capítulo ou um elemento o **arquiva** em vez de apagar;
- `--read-only` desliga toda ferramenta que muda algo.

> Os nomes e as descrições das ferramentas, os códigos de erro e as mensagens do servidor são
> em inglês, exatamente como o servidor os informa. O catálogo abaixo é mantido em inglês.

## Instalação

```sh
tool/build_mcp.sh            # a partir da raiz do repositório; escreve build/plotcraft-mcp
```

(ou rode a partir do código com `dart run packages/plotcraft_mcp/bin/plotcraft_mcp.dart`.)

### Claude Code

```sh
claude mcp add plotcraft -- /caminho/para/plotcraft-mcp --root ~/Documents/plotcraft
```

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "plotcraft": {
      "command": "/caminho/para/plotcraft-mcp",
      "args": ["--root", "/Users/voce/Documents/plotcraft"]
    }
  }
}
```

### Opções

| Opção | Significado |
| --- | --- |
| `--root <pasta>` (ou `PLOTCRAFT_ROOT`) | A pasta de projetos do Plotcraft: cada subpasta com um `project.json` é um projeto. Use a mesma pasta que o aplicativo usa (Preferências → Pasta de projetos). |
| `--project <pasta>` | Uma pasta de projeto extra, fora de `--root` (pode ser repetida). |
| `--read-only` | Recusa toda ferramenta que muda algo. |

## Como a IA deve trabalhar

1. `list_projects` (ou `create_project`) e, depois, passe o **id**, a pasta ou o título
   exato do projeto a todas as outras ferramentas.
2. Leia antes de escrever. `get_chapter` / `get_element` devolvem uma `revision`;
   envie-a de volta como `base_revision`. Um erro `conflict` significa que o arquivo mudou:
   leia de novo e refaça a alteração.
3. Escreva os capítulos em **Markdown**. Ligue um nome a um elemento com
   `[[element:<id>|Nome]]`, mostre uma imagem da galeria com `![](gallery://<id>)`; um
   divisor é `---`. Cores, fontes e tamanhos existem só no formato rico: use `edit_chapter`
   com `format_text`. A mesma operação define os formatos de linha do editor (`header` 1-3,
   `list`, `quote`, `indent`, `align`) e `clear_format` remove a formatação, então tudo o que
   a barra de ferramentas do editor faz com o texto pode ser feito por aqui. Desfazer e refazer
   são do editor: toda escrita é atômica e protegida por `base_revision`, então para refazer
   uma alteração leia o capítulo de novo.
4. Prefira `edit_chapter` (edições precisas que mantêm formatação e ligações) a reescrever um
   capítulo inteiro.

O servidor também publica **recursos** (`plotcraft://guide/data-model`,
`plotcraft://guide/markdown`, `plotcraft://projects` e um modelo por projeto, capítulo,
elemento e imagem da galeria) e **prompts** (`story_bible_from_premise`, `draft_chapter`,
`continuity_check`, `develop_character`, `revise_chapter`).

## Erros

Uma chamada que falha devolve `isError` com `{"error": {"code", "message", "hint"}}`.
Códigos: `notFound`, `conflict`, `validation`, `confirmationRequired`,
`readOnly`, `appNotRunning`, `unsupported`, `timeout`, `io`, `internal`.

## Ferramentas

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

### Ferramentas que precisam do aplicativo aberto

`get_preferences`, `list_themes`, `set_theme`, `set_interface_font`,
`set_language`, `set_projects_root`, `open_in_app`, `spell_check_text`,
`suggest_spelling` e `learn_word` consultam o aplicativo Plotcraft em execução (por meio de
pequenos arquivos de pedido em `<pasta de projetos>/.plotcraft/`). Sem o aplicativo, elas
respondem `appNotRunning`. `get_app_status` diz se ele está aberto. A correção ortográfica
usa o corretor do sistema operacional (hoje, o do macOS).

## Exemplo

> "Crie um romance de mistério chamado *A Estrada de Sal*, com três personagens e um
> primeiro capítulo."

O assistente chama `create_project`, depois `create_element` para cada personagem (criando
primeiro aqueles a quem os outros se ligam), `add_relation`, `write_chapter` com um Markdown
que liga os personagens, e `link_mentions` para qualquer nome que tenha deixado sem ligação.
Enquanto ele trabalha, o aplicativo se atualiza sozinho.

## Desenvolvimento

```sh
cd packages/plotcraft_mcp
dart pub get
dart test                 # cliente em memória para cada ferramenta + uma execução completa por stdio
dart run tool/print_catalog.dart   # a tabela acima
```

Os arquivos do projeto e o que o servidor faz com eles estão descritos em
[`docs/pt-BR/project-model.md`](../../docs/pt-BR/project-model.md) e
[`docs/pt-BR/mcp.md`](../../docs/pt-BR/mcp.md).
