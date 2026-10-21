**English** · [Português](README.pt-BR.md) · [Español](README.es.md)

# Plotcraft website

The site that presents Plotcraft and offers its downloads. It is a Vue 3 + Vite + TypeScript single page, in English, Portuguese and Spanish, with a light and a dark theme taken from the app.

## Run it

```sh
cd website
npm install
npm run dev        # http://localhost:5173
npm test           # unit tests (Vitest)
npm run build      # type check + production build in dist/
```

`npm run dev` and `npm run build` first copy the screenshots (`docs/screenshots/`) and the fonts (`assets/fonts/`) from the app into `public/`, so they have a single source of truth. Those copies are not committed.

## How the downloads work

When the page opens, it asks the GitHub API for the repository's latest release and lists the files by system: the app (`plotcraft-<version>-macos.dmg`, `…-windows-x64.zip`, `…-linux-x64.tar.gz`) and the MCP server (`plotcraft-mcp-<version>-…`), plus the checksums. The visitor's system comes first, and the hero button links straight to its file. A new release therefore shows up without redeploying the site. These file names come from [`.github/workflows/release.yml`](../.github/workflows/release.yml); if they change, update `src/lib/releases.ts`.

While the repository is private, or if GitHub cannot be reached, the section shows a link to the releases page instead. The repository is set in `src/config.ts`.

## Publish it

[`.github/workflows/website.yml`](../.github/workflows/website.yml) builds, tests and deploys the site to GitHub Pages when `website/`, the screenshots or the fonts change on `main`. Turn it on once in **Settings → Pages → Source: GitHub Actions**. The base path is the repository name, set by the workflow through `VITE_BASE`.

## Translating

The texts are in `src/i18n/` (`en.ts` is the reference; `pt.ts` and `es.ts` must have the same keys, which a test checks). To add a language, add its file, list it in `src/i18n/index.ts` and translate the keys.
