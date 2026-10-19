# Plotcraft

Plotcraft é um aplicativo desktop para arquitetar histórias. A proposta vai além de escrever texto: cada história é um projeto organizado, com contexto, metadados e ferramentas para desenvolver seus elementos antes e durante a escrita.

> O aplicativo ainda está em estágio inicial. A documentação descreve a visão e os conceitos pretendidos; não representa funcionalidades já disponíveis.

## Documentação

- [Visão do produto](docs/visao-do-produto.md) — propósito, público e experiência desejada.
- [Modelo de projeto](docs/modelo-de-projeto.md) — o que compõe um projeto de história.
- [Experiência e preferências](docs/experiencia-e-preferencias.md) — foco desktop, temas e idiomas.
- [MCP](docs/mcp.md) — como uma IA cria e gerencia histórias pelo Plotcraft (servidor em [`packages/plotcraft_mcp`](packages/plotcraft_mcp/README.md)).

## Estado atual

A área de projetos permite criar, buscar, ordenar e excluir projetos, além de escolher entre temas, idiomas e fontes. Cada projeto abre em um espaço de trabalho em painéis, com abas para visão geral, configurações, galeria, capítulos e elementos.

Os elementos narrativos (personagens, lugares, objetos, criaturas, organizações, eventos, conceitos, notas e tipos próprios) têm ícone e cor, apelidos, etiquetas, detalhes definidos pelo tipo, imagens da galeria ou do computador, relações, seções e fases ligadas a capítulos. O texto da história é editado na área **Escrita**, em texto rico (fontes, cores, alinhamento, listas, imagens da galeria), com corretor ortográfico do sistema no macOS e menções aos elementos. O **Mapa da história** mostra tudo o que está ligado em um grafo: elementos, relações, capítulos e onde cada elemento é citado. A **Linha do tempo** mostra a história por capítulo (quem aparece onde e onde cada fase começa) e pela cronologia do mundo, com datas livres e posição opcional, para qualquer tipo de história. Os dois aparecem quando o projeto tem elementos, têm zoom (botões, Cmd/Ctrl + roda do mouse ou Cmd/Ctrl +/−), tela cheia (Esc sai) e guardam a exibição entre sessões. No mapa, o painel de exibição ajusta distância, repulsão, tamanho, nomes, tipos de ligação e foco no elemento selecionado. Os dados ficam em arquivos locais na pasta de cada projeto.

## Como executar

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.13) com o suporte a desktop do seu sistema. O corretor ortográfico do sistema só existe no macOS; no Windows e no Linux o editor funciona sem ele.

```sh
flutter pub get
flutter run -d macos        # ou: -d windows, -d linux
```

Outros comandos úteis:

```sh
flutter test                                   # testes do aplicativo
(cd packages/plotcraft_core && dart test)      # testes do núcleo (Dart puro)
(cd packages/plotcraft_mcp && dart test)       # testes do servidor MCP
flutter build macos --release                  # gera o aplicativo
dart run build_runner build --delete-conflicting-outputs   # após mudar uma store MobX
tool/screenshots/run.sh                        # imagens das telas em build/screenshots/
```

Os projetos ficam em arquivos na pasta escolhida em **Preferências → Pasta de projetos** (por padrão, `Documentos/Plotcraft`).

## Como usar o MCP

O servidor MCP deixa uma IA (Claude Code, Claude Desktop e outros clientes) criar e editar os mesmos projetos que o aplicativo abre: capítulos, elementos, relações, fases, galeria e fontes. Ele não precisa do aplicativo aberto; com o aplicativo aberto, o resultado aparece na tela enquanto a IA trabalha, e a IA também pode trocar o tema, abrir um capítulo ou usar o corretor.

**1. Gere o executável** (precisa do Dart, que já vem com o Flutter):

```sh
tool/build_mcp.sh        # escreve build/plotcraft-mcp
```

**2. Registre-o no seu cliente**, apontando para a mesma pasta de projetos que o aplicativo usa:

```sh
# Claude Code
claude mcp add plotcraft -- "$PWD/build/plotcraft-mcp" --root ~/Documents/Plotcraft
```

Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "plotcraft": {
      "command": "/caminho/para/build/plotcraft-mcp",
      "args": ["--root", "/Users/voce/Documents/Plotcraft"]
    }
  }
}
```

Opções: `--root <pasta>` (ou a variável `PLOTCRAFT_ROOT`), `--project <pasta>` para uma pasta de projeto fora da raiz e `--read-only` para impedir qualquer alteração.

**3. Peça em linguagem natural**, por exemplo: *"Crie um romance de mistério chamado A Estrada de Sal, com três personagens e um primeiro capítulo"*. A IA lê antes de escrever, usa revisões para nunca sobrescrever o que você digitou, e pede confirmação explícita antes de apagar qualquer coisa. Se vocês dois editarem o mesmo capítulo, o aplicativo pergunta qual versão fica.

O catálogo completo de ferramentas, os erros e os exemplos estão em [`packages/plotcraft_mcp/README.md`](packages/plotcraft_mcp/README.md); o desenho e a segurança, em [MCP](docs/mcp.md).
