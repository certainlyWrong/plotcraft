[English](../architecture.md) · **Português** · [Español](../es/architecture.md)

# Arquitetura da aplicação

## Organização

O código segue a organização por funcionalidade. `core/` guarda o que não pertence a nenhuma funcionalidade e nunca importa de `features/`; cada funcionalidade tem as camadas `domain`, `data`, `stores` e `presentation` quando precisa delas. As regras de negócio ficam em stores MobX, separadas da interface e do acesso ao disco.

```text
lib/
  main.dart                inicializa dependências, descobre idiomas e inicia o app
  app/                     PlotcraftApp: MaterialApp, localização, tema ativo, estágio e grão de papel
  core/
    platform/              WindowService (tamanho da janela) e corretor ortográfico nativo
    storage/               LocalStorage (preferências com SharedPreferences)
    icons/                 IconRef e IconCatalog (catálogo gerado de ícones do icons_flutter)
    theme/                 ThemeDefinition, fontes da interface, PlotcraftTokens (estágios, raios, movimento) e StageScope
    ui/                    componentes reutilizáveis (botões, etiquetas, campos, diálogos, menus, imagens)
    ui/gris/               o visual de aquarela: fundo, grão, anéis, arcos, traços, revelações (veja visual-language.md)
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
  - `domain/` tem o livro (Deltas), os elementos narrativos, a conversão Delta↔Markdown, o índice de menções e a busca de ocorrências.
  - `data/` tem um repositório por assunto, todos sobre `ProjectFiles` (manifesto e escritas atômicas): `BookRepository`, `NarrativeRepository`, `GalleryRepository` e `ProjectMetadataRepository`. `ProjectWorkspaceRepository` os agrupa e carrega tudo de uma vez.
  - `stores/` tem `ProjectWorkspaceStore`: projeto aberto, manuscrito, galeria, metadados e estados das operações.
  - `stores/` tem também `WorkspaceController` (MobX): abas abertas, painel lateral, inspetor, tamanhos dos painéis, buffers de texto dos capítulos e salvamento automático. Ele não abre diálogos; quem pergunta ao usuário é `WorkspaceActions`.
  - `domain/` também tem os tipos de elemento (`element_type.dart`, `element_type_catalog.dart`), as imagens, relações, âncoras de fase e a migração dos elementos antigos.
  - `presentation/` está dividida em `shell/` (barra de atividades, painel lateral, área de abas e `WorkspaceShell`, que une tudo com divisores arrastáveis), `manuscript/` (editor, barra de ferramentas, prévia e lista de capítulos), `reading/` (modo leitura), `elements/` (lista com busca e filtros, escolha de tipo, editor de tipos, editor de elemento dividido em painéis de imagens, relações, detalhes, seções e fases, e os diálogos de aparência, fase e galeria) e `widgets/` (visão geral, galeria, metadados e inspetor). `workspace_actions.dart` reúne as operações iniciadas pela pessoa (fechar aba, capítulos, galeria, metadados, tela cheia).
- **`features/preferences/`**: `ThemeStore` (catálogo de temas, fonte e persistência) e a página de preferências.
- **`core/ui/`**: os componentes recebem dados e callbacks; cores, foco, bordas e estados vêm do tema ativo. `ProjectImage` mostra imagens da pasta do projeto e `ProportionalImage` as mostra inteiras, na sua própria forma.
- A interface usa ícones Feather do pacote `icons_flutter`; a tipografia padrão é Times New Roman, com famílias empacotadas selecionáveis.
- `assets/translations/`, `assets/themes/` e `assets/fonts/` guardam os idiomas, os temas JSON e as fontes (declaradas em `pubspec.yaml`).

Dependências entre funcionalidades vão sempre em direção a `projects` (domínio e dados); apenas a tela inicial de `projects` compõe as páginas das outras funcionalidades.

O catálogo de ícones (`lib/core/icons/icon_catalog.g.dart`) é gerado por `dart tool/gen_icon_catalog.dart`: o pacote `icons_flutter` não tem um registro nome → ícone, então o script lê as constantes de sete conjuntos e gera referências a elas, o que mantém o tree-shaking. Só o conjunto e o nome do ícone são gravados nos projetos.

Os arquivos `.g.dart` das stores são gerados pelo `mobx_codegen`; edite os arquivos-fonte das stores, não os arquivos gerados.

Os componentes de apresentação recebem dados e callbacks. A lógica de domínio permanece nas stores, para que widgets não façam persistência diretamente.

## Pacotes

O que não depende do Flutter fica em `packages/plotcraft_core` (Dart puro): `StoryProject`, os modelos do livro e dos elementos, os conversores Delta↔Markdown, a edição de Delta sem editor (`DeltaEdit`), os repositórios, `ProjectLibrary`, `StoryWorkspace` e o protocolo da ponte com o aplicativo. Os caminhos dentro do pacote repetem os de `lib/` (`features/...`). O aplicativo importa `package:plotcraft_core/...`; o que desenha, guarda preferências ou fala com o sistema (stores MobX, widgets, `ProjectRepository`, `QuillController`) continua em `lib/`. `packages/plotcraft_mcp` é o servidor MCP (ver [MCP](mcp.md)).

Cores dos modelos são números ARGB (`colorValue`) e ícones são `IconRef {set, name}`; o aplicativo os lê como `Color` e `IconData` por extensões (`element_colors.dart`, `icon_data.dart`).

## Projeto de exemplo

O app leva uma história completa, "Herdeiros do Silêncio", em `assets/sample/herdeiros-do-silencio/` (a pasta de um projeto como as demais, com as imagens da galeria e a capa em JPEG para manter o app leve). Na tela inicial, "Explorar a história de exemplo" aparece enquanto ela não está na biblioteca: `SampleProjectInstaller` copia os arquivos para a pasta de projetos (numa pasta `.partial` que só vira a final ao terminar), a biblioteca é recarregada e o projeto abre. Depois disso ele é um projeto comum, que pode ser editado ou excluído; se for excluído, a ação volta a aparecer. Instalar de novo sem excluir não copia nada. Os arquivos novos do exemplo precisam estar declarados em `pubspec.yaml`, pasta por pasta.

## Persistência

Cada projeto é uma pasta local com manifesto e materiais. As preferências guardam apenas os caminhos da biblioteca, a localização padrão para novos projetos, o tema e a fonte. O `easy_localization` persiste o idioma. Sem preferências anteriores, o idioma inicial é inglês e o tema é Gris Night. O formato em disco está descrito em [Modelo de projeto](project-model.md).

## Extensão

Para adicionar uma tradução, crie `assets/translations/<código>.json` seguindo as mesmas chaves do arquivo `en.json`. A lista de idiomas é montada a partir dos arquivos de tradução empacotados.

Para adicionar um tema, crie um JSON em `assets/themes/` conforme o contrato descrito em [Experiência e preferências](experience-and-preferences.md). Temas padrão continuam declarados em código; temas dos assets são carregados junto deles e aparecem na mesma seleção.

## Limites atuais

A área inicial de desktop permite criar, localizar, ordenar, abrir e excluir projetos, além de configurar idioma, tema, fonte e pasta base em páginas próprias. O projeto aberto é um espaço de trabalho em painéis: barra de atividades, painel lateral com capítulos ou elementos, área de abas (visão geral, configurações do projeto, galeria, mapa da história, linha do tempo, modo leitura, e capítulos e elementos abertos ao mesmo tempo) e inspetor, todos redimensionáveis, com larguras salvas localmente. O editor é de texto rico (`flutter_quill`) para o manuscrito único ou capítulos, com corretor ortográfico do sistema, menções a elementos (`@` ou detecção automática dos nomes), imagens da galeria e fontes do projeto. O índice do livro e os elementos são persistidos em arquivos próprios dentro da pasta do projeto; o workspace coordena essas regras pela `ProjectWorkspaceStore`.
