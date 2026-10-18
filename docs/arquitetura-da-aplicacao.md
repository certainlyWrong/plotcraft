# Arquitetura da aplicação

## Organização

As regras de negócio ficam em stores MobX, separadas da interface e do acesso ao armazenamento local:

- `lib/stores/project_store.dart` mantém a biblioteca, busca, ordenação, localização padrão e exclusão. Recebe o projeto criado para atualizar a lista.
- `lib/features/project_creation/domain/project_creation_input.dart` reúne os dados de entrada e suas regras de validação.
- `lib/features/project_creation/stores/project_creation_store.dart` coordena a criação com MobX e registra o resultado na biblioteca.
- `lib/features/project_creation/data/project_creation_service.dart` valida a capa e escreve a estrutura inicial do projeto no disco; o mesmo serviço materializa registros antigos durante a migração.
- `lib/features/project_creation/presentation/` contém a página de criação e as opções visuais de capa.
- `lib/features/project_workspace/stores/project_workspace_store.dart` mantém o projeto aberto, o manuscrito, a galeria, os metadados e os estados das operações de leitura e escrita.
- `lib/features/project_workspace/data/project_workspace_repository.dart` lê os materiais da pasta, salva o manuscrito e os metadados, gerencia a capa e as imagens da galeria e atualiza o manifesto.
- `lib/features/project_workspace/presentation/` contém a visão geral, a escrita, a galeria e o inspetor contextual do workspace desktop.
- `lib/stores/theme_store.dart` mantém o catálogo de temas, a fonte da interface, carrega temas JSON dos assets e persiste as seleções.
- `lib/models/story_project.dart` define os dados de um projeto e sua serialização.
- `lib/data/project_repository.dart` encontra e exclui pastas de projetos, mantém o índice de caminhos e coordena a migração de registros antigos.
- `lib/data/local_storage.dart` guarda preferências, a pasta base escolhida e o índice de caminhos dos projetos com `SharedPreferences`.
- `lib/theme/theme_definition.dart` define o contrato dos temas e os temas padrão em código.
- `lib/theme/interface_fonts.dart` define a fonte padrão e o catálogo de famílias disponíveis para seleção.
- `lib/main.dart` inicializa dependências, descobre idiomas e inicia o app.
- `lib/app/plotcraft_app.dart` configura `MaterialApp`, localização e tema ativo.
- `lib/features/projects/presentation/project_home_screen.dart` coordena a área de trabalho e conecta as páginas às stores.
- `lib/features/projects/presentation/screens/` contém a página de preferências. A biblioteca abre a página da feature de criação dentro da janela principal.
- `lib/features/projects/presentation/widgets/` contém a barra lateral persistente, barra superior da biblioteca, cartões/grade de projetos e estado vazio.
- `lib/ui/components/` reúne botões, campos de texto, seletores, menus, diálogos (`PlotcraftDialog`, `showConfirmDialog`), botões de ícone, alternador de visões e `ProjectImage` reutilizáveis; cores, foco, bordas e estados visuais vêm do tema ativo. As áreas de biblioteca, criação e preferências compartilham o mesmo shell desktop.
- A interface usa ícones Feather do pacote `icons_flutter`; a tipografia padrão é Times New Roman, com famílias Google Fonts selecionáveis.
- `assets/translations/` contém os arquivos JSON carregados pelo `easy_localization`.
- `assets/themes/` contém temas adicionais em JSON, carregados pelo `ThemeStore`.
- `assets/fonts/` contém os arquivos e as licenças das fontes de interface disponíveis no seletor.

Os arquivos `.g.dart` das stores são gerados pelo `mobx_codegen`; edite os arquivos-fonte das stores, não os arquivos gerados.

Os componentes de apresentação recebem dados e callbacks. A lógica de domínio permanece nas stores, para que widgets não façam persistência diretamente.

## Persistência

Cada projeto é uma pasta local com manifesto e materiais. As preferências guardam apenas os caminhos da biblioteca, a localização padrão para novos projetos, o tema e a fonte. O `easy_localization` persiste o idioma. Sem preferências anteriores, o idioma inicial é inglês e o tema é Violet. O formato em disco está descrito em [Modelo de projeto](modelo-de-projeto.md).

## Extensão

Para adicionar uma tradução, crie `assets/translations/<código>.json` seguindo as mesmas chaves do arquivo `en.json`. A lista de idiomas é montada a partir dos arquivos de tradução empacotados.

Para adicionar um tema, crie um JSON em `assets/themes/` conforme o contrato descrito em [Experiência e preferências](experiencia-e-preferencias.md). Temas padrão continuam declarados em código; temas dos assets são carregados junto deles e aparecem na mesma seleção.

## Limites atuais

A área inicial de desktop permite criar, localizar, ordenar, abrir e excluir projetos, além de configurar idioma, tema, fonte e pasta base em páginas próprias. O projeto aberto oferece visão geral, edição dos metadados e da capa, galeria visual, editor Markdown para manuscrito único ou capítulos e gerenciamento de elementos narrativos. O índice do livro e os elementos são persistidos em arquivos próprios dentro da pasta do projeto; o workspace coordena essas regras pela `ProjectWorkspaceStore`.
