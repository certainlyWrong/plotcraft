<div align="center">

[English](README.md) · **Português** · [Español](README.es.md)

# Plotcraft

**Arquitete histórias antes e durante a escrita.**

Personagens, lugares, relações e capítulos no mesmo lugar, em arquivos locais que são seus.

<img src="docs/screenshots/personagem.png" alt="Plotcraft: a ficha de um personagem ao lado da lista de elementos da história" width="920">

</div>

Plotcraft é um aplicativo desktop para quem escreve histórias de qualquer gênero e formato. Cada história é um projeto organizado, com contexto, metadados e ferramentas para desenvolver seus elementos enquanto o texto cresce: o que você escreve e o que você planeja ficam ligados.

> O aplicativo ainda está em estágio inicial. A documentação descreve a visão e os conceitos pretendidos; nem tudo o que ela cita está pronto.

> As capturas de tela mostram a interface em inglês. A interface do Plotcraft está disponível em inglês e em português.

## Recursos

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
      <b>Escrita.</b> Editor de texto rico com fontes, cores, imagens da galeria, corretor ortográfico do sistema (macOS) e menções aos seus elementos.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/galeria.png" alt="Galeria de imagens em mosaico, cada uma na sua proporção">
      <b>Galeria.</b> Referências visuais em um mosaico que respeita a proporção real de cada imagem.
    </td>
    <td width="50%">
      <img src="docs/screenshots/tema-claro.png" alt="Modo leitura com o tema claro Gris Day">
      <b>O seu visual.</b> Uma interface de aquarela inspirada na arte de Gris, em um tema noturno e um diurno, com temas JSON próprios, várias fontes de interface e fontes que viajam com o projeto.
    </td>
  </tr>
</table>

### Projetos e biblioteca

- **Uma biblioteca de histórias.** Crie, busque, ordene (mais recentes ou por título), abra e exclua projetos. Quando a biblioteca tem mais de um tipo de história, dá para filtrar por ele.
- **Identidade para cada história.** Título, subtítulo, autoria, gênero, descrição, palavras-chave e capa: uma imagem sua ou uma das capas geradas.
- **Visão geral.** Palavras, capítulos, elementos e imagens de um projeto de relance, com os detalhes do projeto editáveis ali mesmo.
- **Qualquer tipo de história.** Datas livres, estrutura opcional e vocabulário que não pressupõe um gênero. Livros hoje; projetos de mangá existem como um esqueleto com elementos e galeria.
- **Sempre em sincronia com a pasta.** A biblioteca percebe projetos que outro programa adiciona, remove ou renomeia na sua pasta de projetos.

### Escrita

- **Manuscrito único ou capítulos.** Um livro pode manter um texto contínuo ou ser dividido em capítulos. Adicione, renomeie, reordene (arrastando) e remova capítulos; os removidos são arquivados, não apagados. Contagem de palavras por capítulo e do livro todo.
- **Um editor de texto rico.** Fontes e tamanhos, negrito, itálico, sublinhado, tachado, cores de texto e de destaque, títulos, listas, citações, recuo, alinhamento, divisores e imagens da sua galeria.
- **Menções que ligam escrita e planejamento.** Digite `@` para ligar um nome a um elemento, ou deixe o Plotcraft detectar os nomes e apelidos que você já escreveu; ignore as palavras que são só coincidência. Passe o mouse sobre um nome para ver o cartão do elemento (capa, resumo, detalhes e a fase em que ele está naquele capítulo) e abra-o com Cmd/Ctrl + clique.
- **Ferramentas do dia a dia.** Busca e substituição, desfazer e refazer, salvamento automático, modo de tela cheia e um corretor ortográfico que usa o do próprio sistema (macOS).
- **Seguro com outros programas.** Se um capítulo muda fora do aplicativo, por exemplo por uma IA ou uma ferramenta de sincronização, o Plotcraft o atualiza na hora, ou pergunta qual versão manter quando você tem edições não salvas.
- **Arquivos simples.** Cada capítulo é salvo como um documento do editor mais uma cópia legível em Markdown.

### Modo leitura

Um capítulo por vez em uma coluna confortável, com barra de progresso do livro todo, tamanhos de texto de 14 a 30, ← → para trocar de capítulo, menções que abrem o elemento e a posição e o tamanho lembrados por projeto. Mostra o que você ainda não salvou e funciona em tela cheia.

### Exporte seu livro

Salve o livro como **EPUB** (abre no Apple Books, Kobo e outros leitores, e o Kindle o aceita pelo *Send to Kindle*), **PDF** com capa, sumário e numeração de páginas, ou uma única página **HTML**. Escolha os capítulos, a capa, o sumário e o idioma do arquivo. Use *Exportar livro* no painel Escrita ou no menu de um projeto; as edições ainda não salvas entram no arquivo. Uma IA faz o mesmo com a ferramenta `export_book`.

### Elementos da história

- **Oito tipos prontos:** personagens, lugares, objetos, criaturas, organizações, eventos, conceitos e notas.
- **Tipos próprios.** Crie tipos como *Feitiço* ou *Facção* com ícone, cor e detalhes próprios: texto curto e longo, números, datas, escolhas, sim/não, links e referências a outros elementos.
- **Para cada elemento:** ícone e cor, outros nomes (apelidos), etiquetas, um resumo, os detalhes do seu tipo, imagens (da galeria ou do computador; a primeira é a capa) e seções livres em Markdown para histórico, regras, mitologia ou pesquisa.
- **Fases.** Mostre como um elemento muda ao longo da história: uma fase pode começar em um capítulo, trazer detalhes alterados e ter imagem própria. O elemento exibido em um capítulo usa a fase em vigor ali.
- **Relações.** Ligue elementos com rótulos que se leem nos dois sentidos ("mentor de" / "aprendiz de"), mais uma nota.
- **Tempo da história.** Diga quando algo acontece com as palavras da própria história ("Ano 312", "três dias antes"), com um número opcional para pôr em ordem.
- **Onde é usado.** Veja todos os lugares em que um elemento é citado no texto e se cada menção está ligada, e quais outros elementos apontam para ele nos detalhes.

### Mapa da história

Um grafo interativo da história inteira: elementos, relações, capítulos, onde cada elemento é citado (a linha engrossa a cada menção) e onde cada fase começa. Filtre por tipo, busque, dê zoom, foque em um elemento e suas ligações, ajuste distância, repulsão, tamanho dos nós, nomes e tipos de ligação no painel de exibição e use a tela cheia. A exibição que você deixou é lembrada.

### Linha do tempo

- **Por capítulo:** uma matriz de quem aparece em qual capítulo, com as fases que começam ali.
- **Por cronologia:** os eventos do mundo em ordem ou em escala, com datas livres. Arraste um cartão para mudar o lugar dele e dê zoom para abrir um trecho apertado.
- As duas aparecem quando o projeto tem elementos, com filtros, busca, zoom, tela cheia e a exibição lembrada.

### Galeria

Imagens de referência em um mosaico em que cada uma mantém a sua proporção. Adicione imagens do computador (ou coloque os arquivos na pasta `gallery` do projeto e atualize), veja-as em tamanho grande com anterior e próxima, e use-as como capa de um elemento, em uma fase ou dentro do texto. Cada imagem tem um ID estável, então as ligações sobrevivem quando você reorganiza.

### O seu visual e o seu idioma

- **Um visual de aquarela** inspirado na arte de Gris: a janela começa cinza e ganha cor conforme você passa da escrita aos elementos da história, ao mapa e à leitura. Dois temas, Gris Night e Gris Day; adicione os seus como um arquivo JSON. Veja a [Linguagem visual](docs/pt-BR/visual-language.md).
- **Interface em inglês e português**, com mais idiomas acrescentados ao incluir um arquivo de tradução. O idioma da interface não limita o idioma da sua história.
- **Fontes.** Escolha a fonte da interface (Times New Roman, DM Sans, Lora, Merriweather, Roboto) e adicione fontes `.ttf`, `.otf` ou `.ttc` a um projeto para que viajem com ele e possam ser usadas no texto.
- **Sua pasta de projetos.** Guarde suas histórias onde quiser; a biblioteca pode reunir projetos de lugares diferentes.

### Arquivos locais, seus para sempre

Cada projeto é uma pasta de arquivos legíveis (Markdown para o texto, JSON para o resto, arquivos de imagem comuns). Copie, faça backup, coloque sob controle de versão ou abra com outras ferramentas. Nada fica preso em um banco de dados e nada é enviado para lugar algum.

### Funciona com IA

Um servidor [MCP](https://modelcontextprotocol.io) embutido deixa o Claude Code, o Claude Desktop e outros clientes criarem e editarem os mesmos projetos que o aplicativo abre, com mais de 60 ferramentas: projetos, capítulos, elementos, tipos, fases, relações, galeria, fontes e até o tema e o idioma do próprio aplicativo. A IA lê antes de escrever, usa revisões para nunca sobrescrever o que você digitou, pede confirmação explícita antes de apagar qualquer coisa e pode rodar em modo somente leitura. Com o aplicativo aberto, você vê as mudanças aparecerem enquanto ela trabalha. Veja [Como usar o MCP](#como-usar-o-mcp).

## Experimente com a história de exemplo

O Plotcraft leva uma história completa, **Herdeiros do Silêncio**, para você explorar sem começar do zero. Na tela inicial, escolha **Explorar a história de exemplo**: ela é copiada para a sua pasta de projetos e abre como qualquer outro projeto.

<div align="center">
  <img src="docs/screenshots/biblioteca.png" alt="A biblioteca do Plotcraft com a história de exemplo" width="720">
</div>

São sete Vozes que sustentam o universo, cada uma com um único portador, passadas em herança por um preço. São 12 capítulos, 25 elementos ligados entre si, dois plots e 30 imagens, o suficiente para ver o mapa, a linha do tempo e o modo leitura funcionando. Todas as capturas de tela deste README vêm dela.

## Download

Há versões prontas para cada sistema desktop na [página de Releases](https://github.com/certainlyWrong/plotcraft/releases):

| Sistema | Arquivo | Como executar |
| --- | --- | --- |
| macOS (Apple Silicon e Intel) | `plotcraft-<versão>-macos.dmg` | Abra a imagem de disco e arraste o **Plotcraft** para **Aplicativos**. |
| Windows (64 bits) | `plotcraft-<versão>-windows-x64.zip` | Descompacte e execute `plotcraft.exe`. |
| Linux (64 bits) | `plotcraft-<versão>-linux-x64.tar.gz` | Extraia e execute `plotcraft/plotcraft`. Precisa do GTK 3 (`libgtk-3-0`). |

O [servidor MCP](#como-usar-o-mcp) também é publicado (`plotcraft-mcp-<versão>-<sistema>`), então você não precisa do Dart para usá-lo. O `SHA256SUMS.txt` traz as somas de verificação de todos os arquivos.

As versões ainda não são assinadas digitalmente, então o sistema avisa na primeira vez:

- **macOS:** clique no aplicativo com a tecla Control, escolha **Abrir** e confirme. Se o macOS disser que o aplicativo está danificado, execute uma vez `xattr -dr com.apple.quarantine /Applications/Plotcraft.app`.
- **Windows:** na janela do SmartScreen, escolha **Mais informações → Executar assim mesmo**.

**Para quem mantém o projeto:** uma versão é construída e publicada por [`.github/workflows/release.yml`](.github/workflows/release.yml) quando uma tag de versão é enviada (`git tag v1.0.0 && git push origin v1.0.0`). Uma tag com hífen, como `v1.0.0-beta.1`, é publicada como pré-lançamento. O workflow também pode ser iniciado à mão, na aba Actions, para testar as construções sem publicar.

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

O catálogo completo de ferramentas, os erros e os exemplos estão em [`packages/plotcraft_mcp/README.pt-BR.md`](packages/plotcraft_mcp/README.pt-BR.md); o desenho e a segurança, em [MCP](docs/pt-BR/mcp.md).

## Documentação

- [Visão do produto](docs/pt-BR/product-vision.md) — propósito, público e experiência desejada.
- [Modelo de projeto](docs/pt-BR/project-model.md) — o que compõe um projeto de história e seus arquivos.
- [Experiência e preferências](docs/pt-BR/experience-and-preferences.md) — foco desktop, temas e idiomas.
- [Linguagem visual](docs/pt-BR/visual-language.md) — o visual de aquarela, seus estágios, efeitos e acessibilidade.
- [Arquitetura da aplicação](docs/pt-BR/architecture.md) — organização do código, pacotes e projeto de exemplo.
- [Site](website/README.pt-BR.md) — o site em Vue que apresenta o Plotcraft e oferece os downloads.
- [MCP](docs/pt-BR/mcp.md) — como uma IA cria e gerencia histórias pelo Plotcraft (servidor em [`packages/plotcraft_mcp`](packages/plotcraft_mcp/README.pt-BR.md)).

A documentação de referência está em inglês; estas são as traduções em português. Também há uma versão em [Español](docs/es/README.md).
