[English](README.md) · **Português** · [Español](README.es.md)

# Site do Plotcraft

O site que apresenta o Plotcraft e oferece os downloads. É uma página única em Vue 3 + Vite + TypeScript, em inglês, português e espanhol, com um tema claro e um escuro tirados do aplicativo.

## Executar

```sh
cd website
npm install
npm run dev        # http://localhost:5173
npm test           # testes unitários (Vitest)
npm run build      # checagem de tipos + build de produção em dist/
```

`npm run dev` e `npm run build` antes copiam as capturas de tela (`docs/screenshots/`) e as fontes (`assets/fonts/`) do aplicativo para `public/`, para que tenham uma única fonte de verdade. Essas cópias não são versionadas.

## Como funcionam os downloads

Ao abrir, a página pergunta à API do GitHub qual é a última versão do repositório e lista os arquivos por sistema: o aplicativo (`plotcraft-<versão>-macos.dmg`, `…-windows-x64.zip`, `…-linux-x64.tar.gz`) e o servidor MCP (`plotcraft-mcp-<versão>-…`), além das somas de verificação. O sistema de quem visita vem primeiro, e o botão do topo leva direto ao arquivo dele. Assim, uma versão nova aparece sem publicar o site de novo. Esses nomes de arquivo vêm de [`.github/workflows/release.yml`](../.github/workflows/release.yml); se mudarem, atualize `src/lib/releases.ts`.

Enquanto o repositório for privado, ou se o GitHub não responder, a seção mostra um link para a página de versões. O repositório é definido em `src/config.ts`.

## Publicar

O [`.github/workflows/website.yml`](../.github/workflows/website.yml) constrói, testa e publica o site no GitHub Pages quando `website/`, as capturas, as fontes ou o app mudam na `main`. Também compila a demo web do Flutter (`flutter build web`) e a coloca em `demo/`, ao lado do site, que é para onde os botões «Experimente» apontam; veja «Demo na web» em [`docs/pt-BR/architecture.md`](../docs/pt-BR/architecture.md). Ative uma vez em **Settings → Pages → Source: GitHub Actions**. O caminho base é o nome do repositório, definido pelo workflow em `VITE_BASE`.

## Traduzir

Os textos ficam em `src/i18n/` (`en.ts` é a referência; `pt.ts` e `es.ts` precisam ter as mesmas chaves, o que um teste confere). Para adicionar um idioma, crie o arquivo, liste-o em `src/i18n/index.ts` e traduza as chaves.
