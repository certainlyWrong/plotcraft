[English](../project-model.md) · [Português](../pt-BR/project-model.md) · **Español**

# Modelo de proyecto

## Principio

Un proyecto es una carpeta local que reúne la identidad de la historia y sus materiales. La estructura fija se ocupa de lo que todas las historias comparten; los formatos de contenido pueden crecer sin exigir que toda historia sea un libro.

## Ubicación

De forma predeterminada, los proyectos nuevos se guardan en `Documentos/Plotcraft` (el directorio de documentos que proporciona el sistema operativo, dentro de la carpeta `Plotcraft`). La carpeta base se puede cambiar en **Preferencias → Carpeta de proyectos**. El cambio vale para los proyectos creados después; los proyectos ya existentes siguen donde se crearon. La biblioteca guarda la ruta de cada proyecto y, por tanto, puede reunir proyectos de lugares distintos.

Cada proyecto recibe una subcarpeta propia, con un nombre derivado del título y un identificador estable. Cambiar el título más adelante no obliga a renombrar la carpeta. El proyecto debe seguir siendo legible al copiarlo a otro ordenador, porque la ruta absoluta no forma parte de su manifiesto.

## Estructura inicial

```text
Documentos/Plotcraft/
  ciudades-de-sal-<id>/
    project.json
    covers/
    gallery/
    content/
      book/
        book.json
        manuscript.delta.json
        manuscript.md
        chapters/
      narrative/
        types.json
        elements/
        attachments/
```

- `project.json` contiene los metadatos comunes y la versión del esquema.
- `covers/` guarda la portada importada, cuando se elige una. Mientras no haya un archivo de portada, `coverIndex` identifica una portada visual generada por la interfaz.
- `gallery/` reúne imágenes de referencia y material visual de la historia. `gallery/index.json` da a cada imagen un ID estable (`g_...`), para que los elementos y el texto se refieran a ella sin usar una ruta. Los archivos colocados a mano en la carpeta reciben un ID en la siguiente lectura; si un archivo desaparece, su entrada sigue en el índice y la imagen aparece como ausente hasta que vuelva.
- Cada documento del libro (el manuscrito único o un capítulo) tiene dos archivos: `<nombre>.delta.json`, la **fuente de la verdad** (el formato Delta del editor, con fuentes, colores, alineación, menciones e imágenes), y `<nombre>.md`, una copia legible generada a partir de él. El color, la fuente y la alineación no tienen forma en Markdown y viven solo en el Delta. Modificar el `.md` desde fuera no cambia el libro.
- `content/book/book.json` define si el libro usa un manuscrito único o capítulos y, en ese caso, guarda su orden y sus títulos. Cada capítulo es un archivo Markdown en `content/book/chapters/<id>.md`.
- `content/narrative/elements/` guarda un JSON por elemento narrativo (personaje, lugar, objeto...). Todos comparten la misma estructura; el tipo es un ID que apunta a un tipo de elemento.
- `content/narrative/types.json` guarda los tipos de elemento **personalizados**. Los ocho tipos predefinidos (`character`, `place`, `object`, `creature`, `organization`, `event`, `concept` y `note`) viven en el código, con IDs estables, y no se graban.
- `content/narrative/attachments/<id del elemento>/` guarda las copias de las imágenes que la persona adjuntó a un elemento desde el ordenador.

## Formato de los documentos del libro

`<nombre>.delta.json` guarda `{schemaVersion: 1, ops: [...]}`. Además del formato estándar del editor, usa: el atributo `mention` (`{id, name}`) en el texto vinculado a un elemento; el embed `gallery-image` (`{id, width?, align?}`), que apunta a una imagen de la galería por su ID; y el embed `divider`. Los proyectos que solo tienen el `.md` (versiones anteriores) se convierten en la primera apertura: el Markdown original se copia a `content/book/migration-backup/` (sin sobrescribir) y se crea el `.delta.json`; si el `.delta.json` está dañado, el capítulo se vuelve a leer desde el `.md` y el archivo dañado se deja como está. Al unir capítulos en un manuscrito único, cada capítulo recibe su título como encabezado, si todavía no lo tiene.

## Fuentes del proyecto

La carpeta `fonts/` guarda archivos `.ttf`, `.otf` o `.ttc` añadidos por la persona, que viajan con el proyecto. El editor ofrece también las fuentes empaquetadas y las instaladas en el ordenador. El texto que usa una fuente que el ordenador no tiene muestra un aviso, y la fuente se puede añadir al proyecto.

## Libro y capítulos

El modo inicial es el de **manuscrito único**. Los proyectos anteriores, que todavía no tienen `book.json`, siguen en ese modo y leen `manuscript.md` con normalidad. Al activar los capítulos, el texto actual se copia al primer capítulo. Al volver al manuscrito único, los capítulos se reúnen, con sus títulos, en `manuscript.md`. La conversión conserva los archivos de origen. Quitar un capítulo lo saca del índice activo y mueve sus archivos (`.delta.json` y `.md`) a `content/book/archive/`. El editor permite añadir, renombrar y reordenar capítulos.

El **modo lectura** muestra el libro como lo vería un lector: un capítulo cada vez, una columna estrecha, tamaño de texto ajustable (de 14 a 30), una barra de progreso de todo el libro, las flechas ← → para cambiar de capítulo y menciones que abren el elemento con un clic (y muestran su tarjeta al pasar el ratón). Lee el texto actual de los búferes, incluido lo que aún no se ha guardado, y recuerda el capítulo y el tamaño por proyecto, en este ordenador. Se abre con el botón del libro del panel de capítulos o de la barra del editor, y funciona en pantalla completa.

El editor guarda Markdown en archivos legibles fuera de Plotcraft. Ofrece formato, búsqueda y reemplazo, historial de deshacer y rehacer, vista previa, vista dividida, guardado automático y un modo de pantalla completa de la ventana. En macOS, el campo de edición consulta el corrector nativo mediante `NSSpellChecker`; en Android e iOS usa el servicio de Flutter. El servicio de corrección para Windows y Linux aún depende de una integración nativa específica.

## Elementos narrativos y referencias

### Tipos de elemento
Un tipo tiene `id`, nombre, icono (`{set, name}` del paquete `icons_flutter`, nunca el código del glifo), color (`#RRGGBB`) y una lista de detalles (`fields`). Cada detalle tiene `id`, etiqueta y clase: texto corto, texto largo, número, fecha, elección (con opciones), sí/no, otro elemento o enlace. Los tipos predefinidos traen detalles estándar con etiquetas traducidas. Un tipo personalizado solo se puede eliminar cuando ningún elemento lo usa.

### Elemento (`schemaVersion` 2)
Campos: `id`, `typeId`, `title`, `aliases` (otros nombres, que también sirven para detectar menciones), `summary`, `tags`, `icon` y `color` (sustituyen a los del tipo, opcionales), `images`, `fields` (valores de los detalles del tipo, por ID), `sections` (texto en Markdown), `phases`, `relations`, `mentionPolicy` (`auto` e `ignoredTerms`), `time` (opcional), `createdAt` y `updatedAt`.

- **Imágenes:** cada elemento de la lista es `{ref: gallery, id}` (una imagen de la galería por su ID) o `{ref: attachment, file}` (una copia en `attachments/`, con una ruta relativa al proyecto). La primera imagen es la portada. Al guardar el elemento, se borran las copias que ya no usa.
- **Fases:** muestran cómo cambia el elemento a lo largo de la historia. Cada fase tiene título, descripción, `anchor` (`chapter` con el ID del capítulo, `manual` con un texto libre, o `none`), `fieldOverrides` (detalles que cambian en esa fase) e `image` (una de las imágenes del elemento).
- **Relaciones:** `{id, targetId, label, reciprocalLabel, note}`. Se guardan solo en el elemento de origen; el otro lado ve la relación mediante un índice derivado en memoria (con la etiqueta recíproca, o la misma etiqueta si no la hay). Las relaciones con elementos que ya no existen se ignoran y se eliminan al guardar.
- **Detalles que apuntan a elementos:** un detalle de clase `element` (uno) o `elements` (varios) guarda IDs de otros elementos, separados por comas, y puede limitar los tipos aceptados (`targetTypes`). El "Dónde" de un evento acepta varios lugares, el "Dueño" de un objeto y el "Líder" de una organización aceptan un personaje, y el "Hábitat" de una criatura acepta lugares. Esos detalles se convierten en enlaces en el mapa y aparecen como "Citado en los detalles de" en el elemento al que apuntan. Los textos de versiones anteriores siguen siendo legibles: un nombre que coincide con el título o el alias de un elemento se reconoce, y lo que no coincide aparece como texto hasta que se sustituya.
- **Tiempo en la historia (`time`):** cuándo ocurre el elemento en el mundo de la historia, como `{label, position}`. La `label` es texto libre, escrito como lo cuenta la historia ("Año 312", "verano de 1987", "tres días antes"), sin exigir un calendario. La `position` es un número opcional que solo sirve para ordenar (mayor = más tarde). Sin `time`, un evento con el detalle "cuándo" rellenado aparece en la cronología sin posición.
- **Menciones:** no se guardan en el elemento. La política (`mentionPolicy`) indica si los nombres y alias se resaltan en el texto y qué términos ignorar.

### Elementos antiguos (`schemaVersion` 1)
Los archivos antiguos tienen un `kind` de texto libre. Siguen siendo legibles: el `kind` pasa a ser el `typeId`. Cuando el valor no es un tipo conocido (por ejemplo `Dragón`), se crea un tipo personalizado con ese nombre, guardado en `types.json`. Los archivos de los elementos no se modifican hasta que el elemento se edita y se guarda.

### Referencias en el texto
El editor inserta referencias con la sintaxis `[[element:<id>|nombre mostrado]]`. El ID sigue siendo válido cuando se renombra el elemento. La vista previa convierte la referencia en un enlace que abre el elemento, y el elemento muestra en qué documentos se cita. Una cadena de extensiones convierte sintaxis propias en algo que la vista previa puede mostrar sin cambiar el Markdown de origen. Al quitar un elemento, su JSON se mueve a `content/narrative/archive/`; las marcas ya escritas permanecen en el texto para recuperarlas o actualizarlas.

## Metadatos comunes

El manifiesto contiene `schemaVersion`, `id`, `title`, `subtitle`, `author`, `description`, `genre`, `tags`, `createdAt`, `updatedAt`, `primaryFormat`, `coverIndex` y `coverFile`. Los campos adicionales de identidad son opcionales. La portada importada, cuando existe, se copia a `covers/` y se referencia con una ruta relativa al proyecto. `primaryFormat` empieza como `book`. Las fechas usan ISO 8601. Los manifiestos anteriores, sin estos campos, siguen siendo legibles con valores vacíos.

Al crear un proyecto, el título debe tener entre 3 y 120 caracteres. El subtítulo, la autoría, el género y la descripción tienen límites de 160, 120, 80 y 2.000 caracteres, respectivamente. Se aceptan hasta ocho palabras clave distintas de hasta 40 caracteres cada una. Las portadas importadas pueden ser PNG, JPEG o WebP de hasta 10 MB. La validación se hace antes de escribir el proyecto en el disco.

El manifiesto es la fuente de los datos de cada proyecto. Las preferencias solo guardan la lista de rutas de las carpetas para que la biblioteca pueda encontrar proyectos en directorios distintos. Ningún archivo del proyecto debe depender de una ruta absoluta guardada en el manifiesto.

## Tipos de proyecto

El `primaryFormat` del manifiesto indica qué clase de historia es el proyecto y se elige al crearlo (no cambia después). Los tipos están en un registro (`ProjectFormats`):

- `book` (libro o novela): tiene manuscrito, con capítulos o un texto único, además de elementos y galería.
- `manga`: por ahora es un esqueleto, solo con vista general, elementos y galería. No crea `content/book/` y el espacio de trabajo no muestra el manuscrito. Las páginas y las viñetas todavía no tienen modelo ni editor.

Un `primaryFormat` desconocido (de una versión más nueva) se abre como libro. La biblioteca muestra el icono del tipo en cada tarjeta y, cuando hay más de un tipo, permite filtrar por él. La vista general del proyecto resume tipo, palabras, capítulos, elementos e imágenes. Los audiolibros y otros formatos pueden ocupar nuevos directorios dentro de `content/` y entrar en el registro.

## Ciclo de vida actual

Crear un proyecto escribe la estructura inicial en el disco y abre su espacio de trabajo. Guardar el manuscrito o un capítulo actualiza `updatedAt` en el manifiesto. Desde la vista general se pueden editar el título, el subtítulo, la autoría, el género, la descripción, las palabras clave y la portada; la imagen de portada se copia a `covers/` y se actualiza el manifiesto. Las fechas y la carpeta son datos generados por el sistema. La vista general muestra miniaturas de las imágenes de la galería. Se pueden añadir imágenes desde la interfaz, que copia los archivos a `gallery/` sin reemplazar nombres existentes, quitarlas con confirmación, o colocarlas directamente en esa carpeta y actualizar la galería. Eliminar un proyecto borra su carpeta y todo su contenido, previa confirmación en la biblioteca. Los proyectos de versiones anteriores, guardados antes solo en las preferencias, se migran a carpetas al cargar la biblioteca.

La aplicación también incluye una historia de ejemplo completa, que se copia a la carpeta de proyectos a petición y, desde entonces, es un proyecto normal (véase [Arquitectura de la aplicación](architecture.md)).
