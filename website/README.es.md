[English](README.md) · [Português](README.pt-BR.md) · **Español**

# Sitio web de Plotcraft

El sitio que presenta Plotcraft y ofrece sus descargas. Es una página única en Vue 3 + Vite + TypeScript, en inglés, portugués y español, con un tema claro y uno oscuro tomados de la aplicación.

## Ejecutarlo

```sh
cd website
npm install
npm run dev        # http://localhost:5173
npm test           # pruebas unitarias (Vitest)
npm run build      # comprobación de tipos + build de producción en dist/
```

Antes, `npm run dev` y `npm run build` copian las capturas de pantalla (`docs/screenshots/`) y las fuentes (`assets/fonts/`) de la aplicación a `public/`, para que tengan una única fuente de verdad. Esas copias no se versionan.

## Cómo funcionan las descargas

Al abrirse, la página pregunta a la API de GitHub por la última versión del repositorio y lista los archivos por sistema: la aplicación (`plotcraft-<versión>-macos.dmg`, `…-windows-x64.zip`, `…-linux-x64.tar.gz`) y el servidor MCP (`plotcraft-mcp-<versión>-…`), además de las sumas de comprobación. El sistema de quien visita va primero, y el botón de la cabecera lleva directo a su archivo. Así, una versión nueva aparece sin volver a publicar el sitio. Esos nombres de archivo vienen de [`.github/workflows/release.yml`](../.github/workflows/release.yml); si cambian, actualiza `src/lib/releases.ts`.

Mientras el repositorio sea privado, o si GitHub no responde, la sección muestra un enlace a la página de versiones. El repositorio se define en `src/config.ts`.

## Publicarlo

[`.github/workflows/website.yml`](../.github/workflows/website.yml) construye, prueba y publica el sitio en GitHub Pages cuando cambian `website/`, las capturas, las fuentes o la app en `main`. También compila la demo web de Flutter (`flutter build web`) y la deja en `demo/` junto al sitio, que es adonde apuntan los botones «Pruébalo»; ver «Demo web» en [`docs/es/architecture.md`](../docs/es/architecture.md). Actívalo una vez en **Settings → Pages → Source: GitHub Actions**. La ruta base es el nombre del repositorio, definida por el workflow en `VITE_BASE`.

## Traducir

Los textos están en `src/i18n/` (`en.ts` es la referencia; `pt.ts` y `es.ts` deben tener las mismas claves, lo que comprueba una prueba). Para añadir un idioma, crea su archivo, inclúyelo en `src/i18n/index.ts` y traduce las claves.
