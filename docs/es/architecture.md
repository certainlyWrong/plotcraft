[English](../architecture.md) · [Português](../pt-BR/architecture.md) · **Español**

# Arquitectura de la aplicación

## Organización

El código sigue una organización por funcionalidad. `core/` guarda lo que no pertenece a ninguna funcionalidad y nunca importa de `features/`; cada funcionalidad tiene las capas `domain`, `data`, `stores` y `presentation` cuando las necesita. Las reglas de negocio viven en stores de MobX, separadas de la interfaz y del acceso al disco.

```text
lib/
  main.dart                inicializa dependencias, descubre idiomas y arranca la app
  app/                     PlotcraftApp: MaterialApp, localización, tema activo, etapa y grano de papel
  core/
    platform/              WindowService (tamaño de la ventana) y corrector ortográfico nativo
    storage/               LocalStorage (preferencias con SharedPreferences)
    icons/                 IconRef e IconCatalog (catálogo generado de iconos de icons_flutter)
    theme/                 ThemeDefinition, fuentes de la interfaz, PlotcraftTokens (etapas, radios, movimiento) y StageScope
    ui/                    componentes reutilizables (botones, etiquetas, campos, diálogos, menús, imágenes)
    ui/gris/               el aspecto de acuarela: fondo, grano, anillos, arcos, trazos, revelaciones (véase visual-language.md)
  features/
    projects/              biblioteca de proyectos
    project_creation/      creación de proyectos
    project_workspace/     espacio de trabajo de un proyecto abierto
    preferences/           tema, fuente, idioma y carpeta de proyectos
```

- **`features/projects/`**
  - `domain/` tiene `StoryProject`, `ProjectMetadataInput` (datos y validación del título, las etiquetas y los demás campos, usados al crear y al editar) y `CoverImageRules` (extensiones y tamaño de la portada).
  - `data/` tiene `ProjectRepository` (carpetas, índice de rutas y migración) y `ProjectCreationService` (estructura inicial en el disco).
  - `stores/` tiene `ProjectStore`.
  - `presentation/` tiene la pantalla de inicio, la barra lateral, la cabecera, las tarjetas y las paletas de portada.
- **`features/project_creation/`**: `ProjectCreationStore` y la página de creación.
- **`features/project_workspace/`**
  - `domain/` tiene el libro (Deltas), los elementos narrativos, la conversión Delta↔Markdown, el índice de menciones y la búsqueda de apariciones.
  - `data/` tiene un repositorio por tema, todos sobre `ProjectFiles` (manifiesto y escrituras atómicas): `BookRepository`, `NarrativeRepository`, `GalleryRepository` y `ProjectMetadataRepository`. `ProjectWorkspaceRepository` los agrupa y carga todo de una vez.
  - `stores/` tiene `ProjectWorkspaceStore`: el proyecto abierto, el manuscrito, la galería, los metadatos y los estados de las operaciones.
  - `stores/` tiene también `WorkspaceController` (MobX): pestañas abiertas, panel lateral, inspector, tamaños de los paneles, búferes de texto de los capítulos y guardado automático. No abre diálogos; quien pregunta al usuario es `WorkspaceActions`.
  - `domain/` tiene además los tipos de elemento (`element_type.dart`, `element_type_catalog.dart`), las imágenes, las relaciones, los anclajes de fase y la migración de los elementos antiguos.
  - `presentation/` se divide en `shell/` (barra de actividades, panel lateral, área de pestañas y `WorkspaceShell`, que lo une todo con divisores arrastrables), `manuscript/` (editor, barra de herramientas, vista previa y lista de capítulos), `reading/` (modo lectura), `elements/` (lista con búsqueda y filtros, selector de tipo, editor de tipos, editor de elemento dividido en paneles de imágenes, relaciones, detalles, secciones y fases, y los diálogos de apariencia, fase y galería) y `widgets/` (vista general, galería, metadatos e inspector). `workspace_actions.dart` reúne las operaciones iniciadas por la persona (cerrar una pestaña, capítulos, galería, metadatos, pantalla completa).
- **`features/preferences/`**: `ThemeStore` (catálogo de temas, fuente y persistencia) y la página de preferencias.
- **`core/ui/`**: los componentes reciben datos y callbacks; los colores, el foco, los bordes y los estados vienen del tema activo. `ProjectImage` muestra imágenes de la carpeta del proyecto y `ProportionalImage` las muestra enteras, con su propia forma.
- La interfaz usa iconos Feather del paquete `icons_flutter`; la tipografía predeterminada es Times New Roman, con familias empaquetadas seleccionables.
- `assets/translations/`, `assets/themes/` y `assets/fonts/` guardan los idiomas, los temas JSON y las fuentes (declaradas en `pubspec.yaml`).

Las dependencias entre funcionalidades van siempre hacia `projects` (dominio y datos); solo la pantalla de inicio de `projects` compone las páginas de las demás funcionalidades.

El catálogo de iconos (`lib/core/icons/icon_catalog.g.dart`) se genera con `dart tool/gen_icon_catalog.dart`: el paquete `icons_flutter` no tiene un registro nombre → icono, así que el script lee las constantes de siete conjuntos y genera referencias a ellas, lo que mantiene el tree-shaking. En los proyectos solo se guardan el conjunto y el nombre del icono.

Los archivos `.g.dart` de las stores los genera `mobx_codegen`; edite los archivos fuente de las stores, no los generados.

Los componentes de presentación reciben datos y callbacks. La lógica de dominio permanece en las stores, para que los widgets no persistan nada directamente.

## Paquetes

Lo que no depende de Flutter vive en `packages/plotcraft_core` (Dart puro): `StoryProject`, los modelos del libro y de los elementos, los conversores Delta↔Markdown, la edición de Delta sin editor (`DeltaEdit`), los repositorios, `ProjectLibrary`, `StoryWorkspace` y el protocolo del puente con la aplicación. Las rutas dentro del paquete repiten las de `lib/` (`features/...`). La aplicación importa `package:plotcraft_core/...`; lo que dibuja, guarda preferencias o habla con el sistema (stores de MobX, widgets, `ProjectRepository`, `QuillController`) sigue en `lib/`. `packages/plotcraft_mcp` es el servidor MCP (véase [MCP](mcp.md)).

Los colores de los modelos son números ARGB (`colorValue`) y los iconos son `IconRef {set, name}`; la aplicación los lee como `Color` e `IconData` mediante extensiones (`element_colors.dart`, `icon_data.dart`).

## Proyecto de ejemplo

La aplicación incluye una historia completa, "Herdeiros do Silêncio", en `assets/sample/herdeiros-do-silencio/` (la carpeta de un proyecto como las demás, con las imágenes de la galería y la portada en JPEG para mantener la aplicación ligera). En la pantalla de inicio, "Explorar la historia de ejemplo" aparece mientras no esté en la biblioteca: `SampleProjectInstaller` copia los archivos a la carpeta de proyectos (en una carpeta `.partial` que solo se convierte en la definitiva al terminar), se recarga la biblioteca y se abre el proyecto. Después es un proyecto normal, que se puede editar o eliminar; si se elimina, la acción vuelve a aparecer. Instalarlo otra vez sin eliminarlo no copia nada. Los archivos nuevos del ejemplo deben estar declarados en `pubspec.yaml`, carpeta por carpeta.

## Demo web

La app también se compila para la web (`flutter build web`), como una demo a la que apunta el sitio. Un navegador no tiene carpetas, así que todos los repositorios leen y escriben a través de `fs`, en `packages/plotcraft_core/lib/core/file_system.dart`: el disco real en el escritorio y un `MemoryFileSystem` (de `package:file`) en el navegador, elegido en `main`. El código que necesita un archivo usa `fs.file(path)` y `fs.directory(path)` en lugar de `File(path)` y `Directory(path)`. En el navegador la app empieza con la historia de ejemplo, así que lo que se escribe desaparece al cerrar la página. Lo que solo existe en el escritorio (la ventana, el corrector del sistema, las fuentes del sistema, el puente del MCP, la vigilancia de la carpeta) queda desactivado allí, y `isMacOS`/`isLinux`/`isWindows`, en `lib/core/platform/platform_support.dart`, sustituyen a `Platform`, que lanza un error en la web. El workflow `Website` compila la demo y la publica en `/demo/`, junto al sitio.

## Persistencia

Cada proyecto es una carpeta local con un manifiesto y materiales. Las preferencias solo guardan las rutas de la biblioteca, la ubicación predeterminada para los proyectos nuevos, el tema y la fuente. `easy_localization` persiste el idioma. Sin preferencias previas, el idioma inicial es el inglés y el tema es Gris Night. El formato en disco se describe en [Modelo de proyecto](project-model.md).

## Extensión

Para añadir una traducción, cree `assets/translations/<código>.json` con las mismas claves que `en.json`. La lista de idiomas se construye a partir de los archivos de traducción empaquetados.

Para añadir un tema, cree un JSON en `assets/themes/` según el contrato descrito en [Experiencia y preferencias](experience-and-preferences.md). Los temas predeterminados siguen declarados en el código; los temas de los assets se cargan junto con ellos y aparecen en la misma selección.

## Límites actuales

El área de inicio de escritorio permite crear, buscar, ordenar, abrir y eliminar proyectos, además de configurar el idioma, el tema, la fuente y la carpeta base en páginas propias. El proyecto abierto es un espacio de trabajo en paneles: barra de actividades, panel lateral con capítulos o elementos, área de pestañas (vista general, ajustes del proyecto, galería, mapa de la historia, línea de tiempo, modo lectura, y capítulos y elementos abiertos a la vez) e inspector, todos redimensionables, con anchos guardados en local. El editor es de texto enriquecido (`flutter_quill`) para el manuscrito único o para los capítulos, con el corrector ortográfico del sistema, menciones a elementos (`@` o detección automática de los nombres), imágenes de la galería y fuentes del proyecto. El índice del libro y los elementos se persisten en archivos propios dentro de la carpeta del proyecto; el workspace coordina esas reglas mediante `ProjectWorkspaceStore`.
