<div align="center">

[English](README.md) · [Português](README.pt-BR.md) · **Español**

# Plotcraft

**Planifica tus historias antes y mientras las escribes.**

Personajes, lugares, relaciones y capítulos en un mismo sitio, en archivos locales que son tuyos.

<img src="docs/screenshots/personagem.png" alt="Plotcraft: la ficha de un personaje junto a la lista de elementos de la historia" width="920">

</div>

Plotcraft es una aplicación de escritorio para quienes escriben historias de cualquier género y formato. Cada historia es un proyecto organizado, con contexto, metadatos y herramientas para desarrollar sus elementos mientras el texto crece: lo que escribes y lo que planificas permanecen conectados.

> La aplicación está en una fase temprana. La documentación describe la visión y los conceptos previstos; no todo lo que menciona está terminado.

> La interfaz de Plotcraft está disponible en inglés y portugués (las capturas de pantalla la muestran en inglés). En esta versión en español, los nombres de los menús y de las opciones se traducen para facilitar la lectura.

## Funciones

<table>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/mapa-da-historia.png" alt="Mapa de la historia: un grafo de elementos, relaciones y capítulos">
      <b>Mapa de la historia.</b> Un grafo con elementos, relaciones, capítulos y dónde se cita cada elemento, con filtros por tipo y foco en el elemento seleccionado.
    </td>
    <td width="50%">
      <img src="docs/screenshots/linha-do-tempo.png" alt="Línea de tiempo por capítulo: quién aparece dónde">
      <b>Línea de tiempo.</b> La historia por capítulo (quién aparece dónde y dónde empieza cada fase) y por la cronología del mundo, con fechas libres y una posición opcional.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/modo-leitura.png" alt="Modo lectura: un capítulo cada vez, en una columna estrecha">
      <b>Modo lectura.</b> El libro como lo vería un lector: un capítulo cada vez, texto ajustable y nombres que abren su elemento con un clic.
    </td>
    <td width="50%">
      <img src="docs/screenshots/editor.png" alt="Editor de texto enriquecido con menciones a elementos">
      <b>Escritura.</b> Un editor de texto enriquecido con fuentes, colores, imágenes de la galería, el corrector ortográfico del sistema (macOS) y menciones a tus elementos.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/galeria.png" alt="Galería de imágenes en mosaico, cada una con su proporción">
      <b>Galería.</b> Referencias visuales en un mosaico que respeta la proporción real de cada imagen.
    </td>
    <td width="50%">
      <img src="docs/screenshots/tema-claro.png" alt="Modo lectura con el tema claro Paper">
      <b>Tu estilo.</b> Ocho temas con variantes clara y oscura, temas JSON propios, varias fuentes de interfaz y fuentes que viajan con el proyecto.
    </td>
  </tr>
</table>

### Proyectos y biblioteca

- **Una biblioteca de historias.** Crea, busca, ordena (más recientes o por título), abre y elimina proyectos. Cuando la biblioteca tiene más de un tipo de historia, puedes filtrar por él.
- **Identidad para cada historia.** Título, subtítulo, autoría, género, descripción, palabras clave y portada: una imagen tuya o una de las portadas generadas.
- **Vista general.** Palabras, capítulos, elementos e imágenes de un proyecto de un vistazo, con los datos del proyecto editables allí mismo.
- **Cualquier tipo de historia.** Fechas libres, estructura opcional y un vocabulario que no presupone un género. Libros hoy; los proyectos de manga existen como un esqueleto con elementos y galería.
- **Siempre sincronizada con la carpeta.** La biblioteca detecta los proyectos que otro programa añade, quita o renombra en tu carpeta de proyectos.

### Escritura

- **Manuscrito único o capítulos.** Un libro puede mantener un texto continuo o dividirse en capítulos. Añade, renombra, reordena (arrastrando) y quita capítulos; los quitados se archivan, no se borran. Recuento de palabras por capítulo y de todo el libro.
- **Un editor de texto enriquecido.** Fuentes y tamaños, negrita, cursiva, subrayado, tachado, colores de texto y de resaltado, títulos, listas, citas, sangría, alineación, separadores e imágenes de tu galería.
- **Menciones que conectan la escritura con la planificación.** Escribe `@` para vincular un nombre a un elemento, o deja que Plotcraft detecte los nombres y alias que ya escribiste; ignora las palabras que son solo coincidencia. Pasa el ratón sobre un nombre para ver la tarjeta del elemento (portada, resumen, detalles y la fase en que está en ese capítulo) y ábrelo con Cmd/Ctrl + clic.
- **Herramientas del día a día.** Búsqueda y reemplazo, deshacer y rehacer, guardado automático, modo de pantalla completa y un corrector ortográfico que usa el del propio sistema (macOS).
- **Seguro con otros programas.** Si un capítulo cambia fuera de la aplicación, por ejemplo por una IA o una herramienta de sincronización, Plotcraft lo actualiza al instante, o te pregunta qué versión conservar cuando tienes ediciones sin guardar.
- **Archivos sencillos.** Cada capítulo se guarda como un documento del editor más una copia legible en Markdown.

### Modo lectura

Un capítulo cada vez en una columna cómoda, con una barra de progreso de todo el libro, tamaños de texto de 14 a 30, ← → para cambiar de capítulo, menciones que abren su elemento y la posición y el tamaño recordados por proyecto. Muestra lo que aún no has guardado y funciona en pantalla completa.

### Elementos de la historia

- **Ocho tipos predefinidos:** personajes, lugares, objetos, criaturas, organizaciones, eventos, conceptos y notas.
- **Tus propios tipos.** Crea tipos como *Hechizo* o *Facción* con su propio icono, color y detalles: texto corto y largo, números, fechas, opciones, sí/no, enlaces y referencias a otros elementos.
- **Para cada elemento:** icono y color, otros nombres (alias), etiquetas, un resumen, los detalles de su tipo, imágenes (de la galería o de tu ordenador; la primera es la portada) y secciones libres en Markdown para trasfondo, reglas, mitología o investigación.
- **Fases.** Muestra cómo cambia un elemento a lo largo de la historia: una fase puede empezar en un capítulo, traer detalles cambiados y tener su propia imagen. El elemento que se muestra en un capítulo usa la fase vigente allí.
- **Relaciones.** Vincula elementos con etiquetas que se leen en los dos sentidos ("mentor de" / "aprendiz de"), más una nota.
- **Tiempo de la historia.** Di cuándo ocurre algo con las palabras de la propia historia ("Año 312", "tres días antes"), con un número opcional para ponerlo en orden.
- **Dónde se usa.** Mira todos los lugares en que se cita un elemento en el texto y si cada mención está vinculada, y qué otros elementos apuntan a él en sus detalles.

### Mapa de la historia

Un grafo interactivo de toda la historia: elementos, relaciones, capítulos, dónde se cita cada elemento (la línea se engrosa con cada mención) y dónde empieza cada fase. Filtra por tipo, busca, haz zoom, céntrate en un elemento y sus conexiones, ajusta la distancia, la repulsión, el tamaño de los nodos, los nombres y los tipos de enlace en el panel de visualización, y usa la pantalla completa. Se recuerda la vista que dejaste.

### Línea de tiempo

- **Por capítulo:** una matriz de quién aparece en qué capítulo, con las fases que empiezan allí.
- **Por cronología:** los eventos del mundo en orden o a escala, con fechas libres. Arrastra una tarjeta para cambiar su lugar y haz zoom para abrir un tramo apretado.
- Ambas aparecen cuando el proyecto tiene elementos, con filtros, búsqueda, zoom, pantalla completa y la vista recordada.

### Galería

Imágenes de referencia en un mosaico en el que cada una conserva su proporción. Añade imágenes desde tu ordenador (o coloca los archivos en la carpeta `gallery` del proyecto y actualiza), míralas en grande con anterior y siguiente, y úsalas como portada de un elemento, en una fase o dentro del texto. Cada imagen tiene un ID estable, así que los vínculos sobreviven cuando reorganizas.

### Tu estilo y tu idioma

- **Ocho temas**, cada uno con variantes clara y oscura: Violet, Paper, Midnight, Lavender, Moss, Rose, Ocean y Plum. Añade los tuyos como un archivo JSON.
- **Interfaz en inglés y portugués**, y se pueden añadir más idiomas incluyendo un archivo de traducción. El idioma de la interfaz no limita el idioma de tu historia.
- **Fuentes.** Elige la fuente de la interfaz (Times New Roman, DM Sans, Lora, Merriweather, Roboto) y añade fuentes `.ttf`, `.otf` o `.ttc` a un proyecto para que viajen con él y se puedan usar en el texto.
- **Tu carpeta de proyectos.** Guarda tus historias donde quieras; la biblioteca puede reunir proyectos de lugares distintos.

### Archivos locales, tuyos para siempre

Cada proyecto es una carpeta de archivos legibles (Markdown para el texto, JSON para el resto, archivos de imagen normales). Cópialo, haz una copia de seguridad, ponlo bajo control de versiones o ábrelo con otras herramientas. Nada queda atrapado en una base de datos y nada se envía a ningún sitio.

### Funciona con IA

Un servidor [MCP](https://modelcontextprotocol.io) integrado permite que Claude Code, Claude Desktop y otros clientes creen y editen los mismos proyectos que abre la aplicación, con más de 60 herramientas: proyectos, capítulos, elementos, tipos, fases, relaciones, galería, fuentes e incluso el tema y el idioma de la propia aplicación. La IA lee antes de escribir, usa revisiones para no sobrescribir nunca lo que has escrito, pide confirmación explícita antes de borrar nada y puede funcionar en modo de solo lectura. Con la aplicación abierta, ves aparecer los cambios mientras trabaja. Consulta [Cómo usar el MCP](#cómo-usar-el-mcp).

## Pruébalo con la historia de ejemplo

Plotcraft incluye una historia completa, **Herdeiros do Silêncio** (en portugués), para que la explores sin empezar de cero. En la pantalla de inicio, elige **Explore the sample story** (en la interfaz en portugués, *Explorar a história de exemplo*): se copia a tu carpeta de proyectos y se abre como cualquier otro proyecto.

<div align="center">
  <img src="docs/screenshots/biblioteca.png" alt="La biblioteca de Plotcraft con la historia de ejemplo" width="720">
</div>

Siete Voces sostienen el universo, cada una con un único portador, transmitidas en herencia a cambio de un precio. La historia tiene 12 capítulos, 25 elementos enlazados entre sí, dos tramas y 30 imágenes: lo suficiente para ver el mapa, la línea de tiempo y el modo lectura en funcionamiento. Todas las capturas de pantalla de este README salen de ella.

## Descarga

Hay versiones listas para cada sistema de escritorio en la [página de Releases](https://github.com/certainlyWrong/plotcraft/releases):

| Sistema | Archivo | Cómo ejecutarlo |
| --- | --- | --- |
| macOS (Apple Silicon e Intel) | `plotcraft-<versión>-macos.dmg` | Abre la imagen de disco y arrastra **Plotcraft** a **Aplicaciones**. |
| Windows (64 bits) | `plotcraft-<versión>-windows-x64.zip` | Descomprímelo y ejecuta `plotcraft.exe`. |
| Linux (64 bits) | `plotcraft-<versión>-linux-x64.tar.gz` | Extráelo y ejecuta `plotcraft/plotcraft`. Necesita GTK 3 (`libgtk-3-0`). |

El [servidor MCP](#cómo-usar-el-mcp) también se publica (`plotcraft-mcp-<versión>-<sistema>`), así que no necesitas Dart para usarlo. `SHA256SUMS.txt` contiene las sumas de comprobación de todos los archivos.

Las versiones todavía no están firmadas digitalmente, por lo que el sistema te avisará la primera vez:

- **macOS:** haz clic en la aplicación con la tecla Control pulsada, elige **Abrir** y confirma. Si macOS dice que la aplicación está dañada, ejecuta una vez `xattr -dr com.apple.quarantine /Applications/Plotcraft.app`.
- **Windows:** en la ventana de SmartScreen, elige **Más información → Ejecutar de todas formas**.

**Para quien mantiene el proyecto:** una versión se construye y se publica con [`.github/workflows/release.yml`](.github/workflows/release.yml) cuando se envía una etiqueta de versión (`git tag v1.0.0 && git push origin v1.0.0`). Una etiqueta con guion, como `v1.0.0-beta.1`, se publica como versión preliminar. El workflow también se puede iniciar a mano, en la pestaña Actions, para probar las construcciones sin publicar.

## Cómo ejecutarlo

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.13) con soporte de escritorio para tu sistema. El corrector ortográfico del sistema solo existe en macOS; en Windows y Linux el editor funciona sin él.

```sh
flutter pub get
flutter run -d macos        # o: -d windows, -d linux
```

Otros comandos útiles:

```sh
flutter test                                   # pruebas de la aplicación
(cd packages/plotcraft_core && dart test)      # pruebas del núcleo (Dart puro)
(cd packages/plotcraft_mcp && dart test)       # pruebas del servidor MCP
flutter build macos --release                  # genera la aplicación
dart run build_runner build --delete-conflicting-outputs   # tras cambiar una store de MobX
tool/screenshots/run.sh                        # imágenes de las pantallas en build/screenshots/
tool/screenshots/readme.sh                     # imágenes del README en docs/screenshots/ (a partir de la historia de ejemplo)
```

Los proyectos se guardan como archivos en la carpeta elegida en **Preferencias → Carpeta de proyectos** (por defecto, `Documentos/Plotcraft`).

## Cómo usar el MCP

El servidor MCP permite que una IA (Claude Code, Claude Desktop y otros clientes) cree y edite los mismos proyectos que abre la aplicación: capítulos, elementos, relaciones, fases, galería y fuentes. No necesita que la aplicación esté abierta; con la aplicación abierta, el resultado aparece en pantalla mientras la IA trabaja, y la IA también puede cambiar el tema, abrir un capítulo o usar el corrector.

**1. Genera el ejecutable** (necesita Dart, que ya viene con Flutter):

```sh
tool/build_mcp.sh        # escribe build/plotcraft-mcp
```

**2. Regístralo en tu cliente**, apuntando a la misma carpeta de proyectos que usa la aplicación:

```sh
# Claude Code
claude mcp add plotcraft -- "$PWD/build/plotcraft-mcp" --root ~/Documents/Plotcraft
```

Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "plotcraft": {
      "command": "/ruta/a/build/plotcraft-mcp",
      "args": ["--root", "/Users/tu-usuario/Documents/Plotcraft"]
    }
  }
}
```

Opciones: `--root <carpeta>` (o la variable `PLOTCRAFT_ROOT`), `--project <carpeta>` para una carpeta de proyecto fuera de la raíz y `--read-only` para impedir cualquier cambio.

**3. Pídelo en lenguaje natural**, por ejemplo: *"Crea una novela de misterio llamada El Camino de la Sal, con tres personajes y un primer capítulo"*. La IA lee antes de escribir, usa revisiones para no sobrescribir nunca lo que has escrito, y pide confirmación explícita antes de borrar nada. Si ambos editáis el mismo capítulo, la aplicación pregunta qué versión se conserva.

El catálogo completo de herramientas, los errores y los ejemplos están en [`packages/plotcraft_mcp/README.es.md`](packages/plotcraft_mcp/README.es.md); el diseño y la seguridad, en [MCP](docs/es/mcp.md).

## Documentación

- [Visión del producto](docs/es/product-vision.md) — propósito, público y experiencia deseada.
- [Modelo de proyecto](docs/es/project-model.md) — qué compone un proyecto de historia y sus archivos.
- [Experiencia y preferencias](docs/es/experience-and-preferences.md) — enfoque de escritorio, temas e idiomas.
- [Arquitectura de la aplicación](docs/es/architecture.md) — organización del código, paquetes y proyecto de ejemplo.
- [MCP](docs/es/mcp.md) — cómo una IA crea y gestiona historias con Plotcraft (servidor en [`packages/plotcraft_mcp`](packages/plotcraft_mcp/README.es.md)).

La documentación de referencia está en inglés; estas son las traducciones al español. También hay una versión en [Português](docs/pt-BR/README.md).
