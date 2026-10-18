# Modelo de projeto

## Princípio

Um projeto é uma pasta local que reúne a identidade da história e seus materiais. A estrutura fixa cuida do que todas as histórias compartilham; os formatos de conteúdo podem crescer sem exigir que toda história seja um livro.

## Localização

Por padrão, projetos novos ficam em `Documentos/Plotcraft` (o diretório de documentos fornecido pelo sistema operacional, dentro da pasta `Plotcraft`). A pasta base pode ser alterada em **Preferências → Pasta de projetos**. A alteração vale para projetos criados depois dela; projetos já existentes continuam onde foram criados. A biblioteca guarda o caminho de cada projeto e pode, portanto, reunir projetos de locais diferentes.

Cada projeto recebe uma subpasta própria, com um nome derivado do título e um identificador estável. Mudar o título futuramente não precisa renomear a pasta. O projeto deve continuar legível ao ser copiado para outro computador, pois o caminho absoluto não faz parte de seu manifesto.

## Estrutura inicial

```text
Documentos/Plotcraft/
  cidades-de-sal-<id>/
    project.json
    covers/
    gallery/
    content/
      book/
        book.json
        manuscript.md
        chapters/
      narrative/
        types.json
        elements/
        attachments/
```

- `project.json` contém os metadados comuns e a versão do esquema.
- `covers/` guarda a capa importada, quando escolhida. Enquanto não houver arquivo de capa, `coverIndex` identifica uma capa visual gerada pela interface.
- `gallery/` reúne imagens de referência e materiais visuais da história. `gallery/index.json` dá a cada imagem um ID estável (`g_...`), para que elementos e textos se refiram a ela sem usar caminho. Arquivos colocados na pasta à mão ganham um ID na leitura seguinte; se um arquivo some, a entrada continua no índice e a imagem aparece como ausente até voltar.
- `content/book/manuscript.md` é o ponto de partida textual criado automaticamente para um projeto novo.
- `content/book/book.json` define se o livro usa manuscrito único ou capítulos e, nesse caso, guarda a ordem e os títulos. Cada capítulo é um arquivo Markdown em `content/book/chapters/<id>.md`.
- `content/narrative/elements/` guarda um JSON por elemento narrativo (personagem, lugar, objeto...). Todos compartilham a mesma estrutura; o tipo é um ID que aponta para um tipo de elemento.
- `content/narrative/types.json` guarda os tipos de elemento **personalizados**. Os oito tipos pré-criados (`character`, `place`, `object`, `creature`, `organization`, `event`, `concept` e `note`) ficam no código, com IDs estáveis, e não são gravados.
- `content/narrative/attachments/<id do elemento>/` guarda as cópias das imagens que a pessoa anexou do computador a um elemento.

## Livro e capítulos

O modo inicial é **manuscrito único**. Projetos anteriores, que ainda não possuem `book.json`, continuam nesse modo e leem normalmente `manuscript.md`. Ao ativar capítulos, o texto atual é copiado para o primeiro capítulo. Ao voltar para manuscrito único, os capítulos são reunidos com títulos em `manuscript.md`. A conversão preserva os arquivos de origem. Remover um capítulo o tira do índice ativo e move o arquivo para `content/book/archive/`. O editor permite adicionar, renomear e reordenar capítulos.

O editor grava Markdown em arquivos legíveis fora do Plotcraft. Oferece formatação, busca e substituição, histórico de desfazer e refazer, prévia, visualização dividida, salvamento automático e modo de tela cheia da janela. No macOS, o campo de edição consulta o corretor nativo via `NSSpellChecker`; em Android e iOS usa o serviço do Flutter. O serviço de correção para Windows e Linux ainda depende de uma integração nativa específica.

## Elementos narrativos e referências

### Tipos de elemento
Um tipo tem `id`, nome, ícone (`{set, name}` do pacote `icons_flutter`, nunca o código do glifo), cor (`#RRGGBB`) e uma lista de detalhes (`fields`). Cada detalhe tem `id`, rótulo e tipo: texto curto, texto longo, número, data, escolha (com opções), sim/não, outro elemento ou link. Os tipos pré-criados trazem detalhes padrão com rótulos traduzidos. Um tipo personalizado só pode ser excluído quando nenhum elemento o usa.

### Elemento (`schemaVersion` 2)
Campos: `id`, `typeId`, `title`, `aliases` (outros nomes, usados também para detectar menções), `summary`, `tags`, `icon` e `color` (substituem os do tipo, opcionais), `images`, `fields` (valores dos detalhes do tipo, por ID), `sections` (texto em Markdown), `phases`, `relations`, `mentionPolicy` (`auto` e `ignoredTerms`), `createdAt` e `updatedAt`.

- **Imagens:** cada item é `{ref: gallery, id}` (imagem da galeria por ID) ou `{ref: attachment, file}` (cópia em `attachments/`, com caminho relativo ao projeto). A primeira imagem é a capa. Ao salvar o elemento, cópias que ele deixou de usar são apagadas.
- **Fases:** mostram como o elemento muda ao longo da história. Cada fase tem título, descrição, `anchor` (`chapter` com o ID do capítulo, `manual` com um texto livre, ou `none`), `fieldOverrides` (detalhes que mudam nessa fase) e `image` (uma das imagens do elemento).
- **Relações:** `{id, targetId, label, reciprocalLabel, note}`. Ficam gravadas só no elemento de origem; o outro lado enxerga a relação por um índice derivado em memória (com o rótulo recíproco, ou o mesmo rótulo se não houver). Relações para elementos que não existem mais são ignoradas e removidas ao salvar.
- **Menções:** não são gravadas no elemento. A política (`mentionPolicy`) diz se nomes e apelidos são destacados no texto e quais termos ignorar.

### Elementos antigos (`schemaVersion` 1)
Arquivos antigos têm um `kind` em texto livre. Eles continuam legíveis: o `kind` vira o `typeId`. Quando o valor não é um tipo conhecido (por exemplo `Dragão`), é criado um tipo personalizado com esse nome, salvo em `types.json`. Os arquivos dos elementos não são alterados até que o elemento seja editado e salvo.

### Referências no texto
O editor insere referências com a sintaxe `[[element:<id>|nome exibido]]`. O ID continua válido quando o elemento é renomeado. A prévia transforma a referência em um link para abrir o elemento, e o elemento mostra em quais documentos é citado. Um pipeline de extensões transforma sintaxes próprias para a prévia sem mudar o Markdown de origem. Ao remover um elemento, seu JSON é movido para `content/narrative/archive/`; as marcas já escritas permanecem no texto para recuperação ou atualização.

## Metadados comuns

O manifesto contém `schemaVersion`, `id`, `title`, `subtitle`, `author`, `description`, `genre`, `tags`, `createdAt`, `updatedAt`, `primaryFormat`, `coverIndex` e `coverFile`. Os campos adicionais de identidade são opcionais. A capa importada, quando existir, é copiada para `covers/` e referenciada por caminho relativo ao projeto. `primaryFormat` começa como `book`. Datas usam ISO 8601. Manifestos anteriores, sem esses campos, continuam legíveis com valores vazios.

Na criação, o título deve ter de 3 a 120 caracteres. Subtítulo, autoria, gênero e descrição têm limites de 160, 120, 80 e 2.000 caracteres, respectivamente. São aceitas até oito palavras-chave distintas de até 40 caracteres cada. Capas importadas podem ser PNG, JPEG ou WebP de até 10 MB. A validação acontece antes da escrita do projeto em disco.

O manifesto é a fonte dos dados de cada projeto. As preferências guardam somente a lista de caminhos das pastas para que a biblioteca possa localizar projetos em diferentes diretórios. Nenhum arquivo do projeto deve depender de um caminho absoluto salvo no manifesto.

## Outros formatos

A estrutura comum permanece válida para audiolivros, mangás e outros formatos. Seus materiais podem ocupar novos diretórios dentro de `content/`, por exemplo `content/audiobook/` ou `content/manga/`. Esses formatos ainda não possuem modelo de capítulos, páginas, faixas ou interface de edição definidos. `primaryFormat` permite identificar o formato principal sem limitar a história a um único tipo de material.

## Ciclo de vida atual

Criar um projeto escreve a estrutura inicial em disco e abre seu espaço de trabalho. Salvar o manuscrito ou um capítulo atualiza `updatedAt` no manifesto. Pela visão geral, é possível editar título, subtítulo, autoria, gênero, descrição, palavras-chave e capa; a imagem da capa é copiada para `covers/`, e o manifesto é atualizado. As datas e a pasta são dados gerados pelo sistema. A visão geral mostra prévias das imagens da galeria. É possível adicionar imagens pela interface, que copia os arquivos para `gallery/` sem substituir nomes existentes, removê-las com confirmação, ou colocá-las diretamente nessa pasta e atualizar a galeria. Excluir um projeto remove sua pasta e todo o conteúdo, mediante confirmação na biblioteca. Projetos de versões anteriores, antes salvos apenas nas preferências, são migrados para pastas ao carregar a biblioteca.
