[English](../mcp.md) · **Português** · [Español](../es/mcp.md)

# MCP: uma IA que cria e gerencia histórias

O Plotcraft tem um servidor [MCP](https://modelcontextprotocol.io) que deixa uma IA (Claude Code, Claude Desktop e outros clientes) trabalhar nos mesmos projetos que você abre no aplicativo. O servidor, suas ferramentas e mensagens são em **inglês**; esta página explica o desenho. O guia de uso, com o catálogo completo de ferramentas, está em [`packages/plotcraft_mcp/README.md`](../../packages/plotcraft_mcp/README.pt-BR.md).

## Como as peças se encaixam

```text
packages/
  plotcraft_core/   Dart puro: modelos, conversores Delta↔Markdown, repositórios,
                    ProjectLibrary, StoryWorkspace e o protocolo da ponte
  plotcraft_mcp/    o executável stdio (ferramentas, recursos e prompts)
lib/                o aplicativo Flutter, que usa o plotcraft_core
```

- **O servidor lê e grava as pastas dos projetos** (o mesmo formato do aplicativo, descrito em [Modelo de projeto](project-model.md)). Não precisa do aplicativo aberto.
- **`StoryWorkspace`** (em `plotcraft_core`) reúne as operações sobre um projeto sem interface: ler e escrever capítulos, elementos, tipos, galeria e fontes. Serve de base para as ferramentas.
- **`DeltaEdit`** edita o texto rico (substituir, inserir, formatar, ligar menções, inserir divisor ou imagem) sem um editor, mantendo a formatação ao redor.

## Segurança do conteúdo

- **Revisões.** Toda leitura de capítulo ou elemento devolve uma `revision` (impressão digital do arquivo). Uma escrita sobre conteúdo existente a envia como `base_revision`; se o arquivo mudou no meio do caminho, a ferramenta responde `conflict` e a IA lê de novo, em vez de sobrescrever.
- **Confirmação explícita.** Excluir projeto, remover capítulo, elemento ou tipo, e apagar imagem ou fonte exigem `confirm: true` e o nome exato do alvo em `confirm_name`. Remover capítulo ou elemento *arquiva* (recuperável); excluir projeto, imagem da galeria e fonte são definitivos.
- **Somente leitura.** `--read-only` desliga toda ferramenta que muda algo.
- **Auditoria.** Cada escrita grava uma linha em `<projeto>/.plotcraft/mcp-log.jsonl` (textos longos aparecem só pelo tamanho).

## O aplicativo acompanha a IA

Enquanto um projeto está aberto, o aplicativo observa a pasta dele (`ProjectChangeWatcher`) e recarrega o que mudou por fora:

- capítulo **sem alterações suas**: o texto é atualizado na hora, como uma mudança remota (sem passar pelo histórico de desfazer);
- capítulo **com alterações não salvas**: o aplicativo mantém o seu texto, suspende o salvamento automático daquele capítulo e mostra uma faixa — *Carregar a nova* ou *Manter a minha*;
- elementos: a lista é recarregada; um editor aberto sem alterações é refeito, e um com alterações mostra a mesma faixa;
- capítulos criados, renomeados, reordenados ou removidos aparecem na lista, e abas de capítulos removidos se fecham.

A biblioteca também observa a pasta de projetos (`LibraryWatcher`): um projeto criado pela IA aparece sem reabrir o aplicativo.

## Ponte com o aplicativo

Algumas coisas só o aplicativo aberto sabe fazer: trocar tema, fonte ou idioma, abrir um capítulo ou elemento na tela e usar o corretor ortográfico do sistema. Para isso o servidor e o aplicativo trocam arquivos em `<pasta de projetos>/.plotcraft/`:

| Arquivo | Quem escreve | Para quê |
| --- | --- | --- |
| `app.json` | aplicativo (a cada 3 s) | batimento: versão, tema, idioma, projeto aberto |
| `inbox/<id>.json` | servidor | um pedido (`method`, `params`) |
| `outbox/<id>.json` | aplicativo | a resposta (`ok`/`error`) |

Sem o batimento (aplicativo fechado, ou aberto com outra pasta de projetos), essas ferramentas respondem `appNotRunning`. O aplicativo não troca de projeto se o aberto tem alterações não salvas.

## Testes

- `packages/plotcraft_core/test`: conversores, `DeltaEdit`, `StoryWorkspace`, `ProjectLibrary`, ponte.
- `packages/plotcraft_mcp/test`: um cliente MCP em memória chama **cada** ferramenta (sucesso, validação, `conflict`, confirmação, somente leitura) e um teste sobe o executável de verdade por stdio.
- `test/` do aplicativo: observadores de arquivos, recarga de capítulos e elementos, conflito e a ponte.
