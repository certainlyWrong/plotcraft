<div align="center">

# Plotcraft

**Arquitete histórias antes e durante a escrita.**

Personagens, lugares, relações e capítulos no mesmo lugar, em arquivos locais que são seus.

<img src="docs/screenshots/personagem.png" alt="Plotcraft: a ficha de um personagem ao lado da lista de elementos da história" width="920">

</div>

Plotcraft é um aplicativo desktop para quem escreve histórias de qualquer gênero e formato. Cada história é um projeto organizado, com contexto, metadados e ferramentas para desenvolver seus elementos enquanto o texto cresce: o que você escreve e o que você planeja ficam ligados.

> O aplicativo ainda está em estágio inicial. A documentação descreve a visão e os conceitos pretendidos; nem tudo o que ela cita está pronto.

## O que dá para fazer

<table>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/mapa-da-historia.png" alt="Mapa da história: grafo de elementos, relações e capítulos">
      <b>Mapa da história.</b> Um grafo com elementos, relações, capítulos e onde cada elemento é citado, com filtros por tipo e foco no elemento selecionado.
    </td>
    <td width="50%">
      <img src="docs/screenshots/linha-do-tempo.png" alt="Linha do tempo por capítulo: quem aparece onde">
      <b>Linha do tempo.</b> A história por capítulo (quem aparece onde e onde cada fase começa) e pela cronologia do mundo, com datas livres e posição opcional.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/modo-leitura.png" alt="Modo leitura: um capítulo por vez, em coluna estreita">
      <b>Modo leitura.</b> O livro como um leitor o veria: um capítulo por vez, texto ajustável e nomes que abrem o elemento com um clique.
    </td>
    <td width="50%">
      <img src="docs/screenshots/editor.png" alt="Editor de texto rico com menções a elementos">
      <b>Escrita.</b> Editor de texto rico com fontes, cores, imagens da galeria, corretor ortográfico do sistema (macOS) e menções aos elementos.
    </td>
  </tr>
  <tr>
    <td colspan="2">
      <img src="docs/screenshots/galeria.png" alt="Galeria de imagens em mosaico, cada uma na sua proporção">
      <b>Galeria.</b> Referências visuais em mosaico que respeita a proporção real de cada imagem, ligadas a elementos e fases.
    </td>
  </tr>
</table>

Mais do que isso:

- **Elementos narrativos** com ícone e cor: personagens, lugares, objetos, criaturas, organizações, eventos, conceitos, notas e tipos próprios com os detalhes que a sua história pede.
- **Fases e relações:** mostre como um elemento muda ao longo dos capítulos e como ele se liga aos outros.
- **Qualquer história:** datas livres, formatos diferentes (livro, mangá) e vocabulário sem pressupor um gênero.
- **Arquivos locais:** cada projeto é uma pasta legível, com Markdown e JSON, que você pode copiar, versionar ou abrir fora do app.
- **Feito para uma IA ajudar:** um servidor [MCP](docs/mcp.md) deixa o Claude Code, o Claude Desktop e outros clientes criarem e editarem os mesmos projetos.
- **Temas, idiomas e fontes:** interface em português e inglês, vários temas e fontes do projeto.

## Experimente com a história de exemplo

O Plotcraft leva uma história completa, **Herdeiros do Silêncio**, para você explorar sem começar do zero. Na tela inicial, escolha **Explorar a história de exemplo**: ela é copiada para a sua pasta de projetos e abre como qualquer outro projeto.

São sete Vozes que sustentam o universo, cada uma com um único portador, passadas em herança por um preço. São 12 capítulos, 25 elementos ligados entre si, dois plots e 30 imagens, o suficiente para ver o mapa, a linha do tempo e o modo leitura funcionando. Todas as capturas de tela deste README vêm dela.

## Documentação

- [Visão do produto](docs/visao-do-produto.md) — propósito, público e experiência desejada.
- [Modelo de projeto](docs/modelo-de-projeto.md) — o que compõe um projeto de história.
- [Experiência e preferências](docs/experiencia-e-preferencias.md) — foco desktop, temas e idiomas.
- [Arquitetura da aplicação](docs/arquitetura-da-aplicacao.md) — organização do código, pacotes e projeto de exemplo.
- [MCP](docs/mcp.md) — como uma IA cria e gerencia histórias pelo Plotcraft (servidor em [`packages/plotcraft_mcp`](packages/plotcraft_mcp/README.md)).

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
tool/screenshots/readme.sh                     # imagens do README em docs/screenshots/ (a partir da história de exemplo)
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
