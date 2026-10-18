# Arquitetura da aplicação

## Organização

O código segue a organização por funcionalidade. `core/` guarda o que não pertence a nenhuma funcionalidade e nunca importa de `features/`; cada funcionalidade tem as camadas `domain`, `data`, `stores` e `presentation` quando precisa delas. As regras de negócio ficam em stores MobX, separadas da interface e do acesso ao disco.

```text
lib/
  main.dart                inicializa dependências, descobre idiomas e inicia o app
  app/                     PlotcraftApp: MaterialApp, localização e tema ativo
  core/
    platform/              WindowService (tamanho da janela) e corretor ortográfico nativo
    storage/               LocalStorage (preferências com SharedPreferences)
    theme/                 ThemeDefinition, fontes da interface, PlotcraftTokens e PlotcraftRadii
    ui/                    componentes reutilizáveis (botões, campos, diálogos, menus, imagens)
  features/
    projects/              biblioteca de projetos
    project_creation/      criação de projetos
    project_workspace/     espaço de trabalho de um projeto aberto
    preferences/           tema, fonte, idioma e pasta de projetos
```

- **`features/projects/`**
  - `domain/` tem `StoryProject`, `ProjectMetadataInput` (dados e validação de título, tags e demais campos, usados na criação e na edição) e `CoverImageRules` (extensões e tamanho da capa).
  - `data/` tem `ProjectRepository` (pastas, índice de caminhos e migração) e `ProjectCreationService` (estrutura inicial no disco).
  - `stores/` tem `ProjectStore`.
  - `presentation/` tem a tela inicial, a barra lateral, o cabeçalho, os cartões e as paletas de capa.
- **`features/project_creation/`**: `ProjectCreationStore` e a página de criação.
- **`features/project_workspace/`**
  - `domain/` tem o livro, os elementos narrativos e as extensões de Markdown.
  - `data/` tem um repositório por assunto, todos sobre `ProjectFiles` (manifesto e escritas atômicas): `BookRepository`, `NarrativeRepository`, `GalleryRepository` e `ProjectMetadataRepository`. `ProjectWorkspaceRepository` os agrupa e carrega tudo de uma vez.
  - `stores/` tem `ProjectWorkspaceStore`: projeto aberto, manuscrito, galeria, metadados e estados das operações.
  - `stores/` tem também `WorkspaceController` (MobX): abas abertas, painel lateral, inspetor, tamanhos dos painéis, buffers de texto dos capítulos e salvamento automático. Ele não abre diálogos; quem pergunta ao usuário é `WorkspaceActions`.
  - `presentation/` está dividida em `shell/` (barra de atividades, painel lateral, área de abas e `WorkspaceShell`, que une tudo com divisores arrastáveis), `manuscript/` (editor, barra de ferramentas, prévia e lista de capítulos), `elements/` (lista, editor de elemento e diálogo de título e texto) e `widgets/` (visão geral, galeria, metadados e inspetor). `workspace_actions.dart` reúne as operações iniciadas pela pessoa (fechar aba, capítulos, galeria, metadados, tela cheia).
- **`features/preferences/`**: `ThemeStore` (catálogo de temas, fonte e persistência) e a página de preferências.
- **`core/ui/`**: os componentes recebem dados e callbacks; cores, foco, bordas e estados vêm do tema ativo. `ProjectImage` mostra imagens da pasta do projeto.
- A interface usa ícones Feather do pacote `icons_flutter`; a tipografia padrão é Times New Roman, com famílias empacotadas selecionáveis.
- `assets/translations/`, `assets/themes/` e `assets/fonts/` guardam os idiomas, os temas JSON e as fontes (declaradas em `pubspec.yaml`).

Dependências entre funcionalidades vão sempre em direção a `projects` (domínio e dados); apenas a tela inicial de `projects` compõe as páginas das outras funcionalidades.

Os arquivos `.g.dart` das stores são gerados pelo `mobx_codegen`; edite os arquivos-fonte das stores, não os arquivos gerados.

Os componentes de apresentação recebem dados e callbacks. A lógica de domínio permanece nas stores, para que widgets não façam persistência diretamente.

## Persistência

Cada projeto é uma pasta local com manifesto e materiais. As preferências guardam apenas os caminhos da biblioteca, a localização padrão para novos projetos, o tema e a fonte. O `easy_localization` persiste o idioma. Sem preferências anteriores, o idioma inicial é inglês e o tema é Violet. O formato em disco está descrito em [Modelo de projeto](modelo-de-projeto.md).

## Extensão

Para adicionar uma tradução, crie `assets/translations/<código>.json` seguindo as mesmas chaves do arquivo `en.json`. A lista de idiomas é montada a partir dos arquivos de tradução empacotados.

Para adicionar um tema, crie um JSON em `assets/themes/` conforme o contrato descrito em [Experiência e preferências](experiencia-e-preferencias.md). Temas padrão continuam declarados em código; temas dos assets são carregados junto deles e aparecem na mesma seleção.

## Limites atuais

A área inicial de desktop permite criar, localizar, ordenar, abrir e excluir projetos, além de configurar idioma, tema, fonte e pasta base em páginas próprias. O projeto aberto é um espaço de trabalho em painéis: barra de atividades, painel lateral com capítulos ou elementos, área de abas (visão geral, configurações do projeto, galeria, capítulos e elementos abertos ao mesmo tempo) e inspetor, todos redimensionáveis, com larguras salvas localmente. O editor ainda é Markdown para manuscrito único ou capítulos. O índice do livro e os elementos são persistidos em arquivos próprios dentro da pasta do projeto; o workspace coordena essas regras pela `ProjectWorkspaceStore`.
