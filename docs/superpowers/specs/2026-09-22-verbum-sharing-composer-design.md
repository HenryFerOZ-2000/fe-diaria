# Compositor de tarjetas para compartir en Verbum

**Fecha:** 2026-09-22  
**Estado:** diseño aprobado en conversación  
**Alcance:** Android y código Flutter compartido; preparado para iOS sin crear una publicación de App Store inexistente

## 1. Propósito

Verbum debe transformar cualquier versículo u oración compatible en una tarjeta atractiva y reconocible, lista para compartir sin que el usuario tenga que diseñarla. La experiencia debe sentirse como una extensión natural de la aplicación, funcionar sin conexión y mantener el texto legible en cualquier formato.

El éxito de esta entrega significa que:

- un toque en **Compartir** abre una vista previa ya compuesta;
- el formato inicial es 4:5 y puede cambiarse a 1:1 o 9:16;
- Verbum escoge automáticamente un estilo apropiado y permite cambiarlo;
- las oraciones largas se dividen en varias tarjetas completas y numeradas;
- compartir, guardar y copiar funcionan en dispositivos Android compatibles;
- todas las entradas incluidas utilizan el mismo lenguaje visual y el mismo flujo;
- el usuario nunca recibe una imagen ilegible, cortada o silenciosamente incompleta.

## 2. Decisiones de producto aprobadas

1. Se utilizarán únicamente fondos y recursos oficiales de Verbum. No habrá selector de fotografías de la galería.
2. El formato predeterminado será vertical 4:5, de 1080 × 1350 píxeles.
3. También estarán disponibles 1:1, de 1080 × 1080, y 9:16, de 1080 × 1920.
4. Verbum elegirá el ambiente inicial según el contenido. El usuario podrá cambiarlo deslizando o pulsando una miniatura.
5. Los textos largos se repartirán automáticamente entre varias tarjetas. Todas se compartirán juntas y mostrarán una numeración del tipo `1 de 3`.
6. El logotipo real de Verbum aparecerá de forma discreta dentro de la imagen. No se usará una letra “V” inventada como marca.
7. El enlace de descarga no se imprimirá en la tarjeta: acompañará la publicación como texto pulsable.
8. No se añadirá un código QR en esta versión.
9. La acción principal será **Compartir tarjeta**. **Guardar** será secundaria y **Copiar texto y enlace** estará en el menú de opciones.
10. La aplicación utilizará la hoja nativa de Android para escoger el destino; no se construirá una lista propia de redes sociales.

## 3. Lenguaje visual

La ventana de composición conservará el sistema vigente de Verbum:

- fondo ambiental crema con halos morados y dorados;
- superficies cálidas, bordes suaves y radios amplios;
- títulos editoriales con Playfair Display y controles con Inter;
- morado profundo como acción principal y dorado como acento;
- cabecera editorial con el rótulo `CREA Y COMPARTE`, título `Comparte la Palabra`, icono de marca y cierre consistente con `VerbumHeaderButton`;
- vista previa dentro de una superficie elevada, sin parecer un editor externo;
- controles compactos que no compitan con el contenido.

Los tres ambientes iniciales serán:

- **Luz serena:** crema, dorado suave y morado; preferido para versículos, esperanza y contenido diario.
- **Noche contemplativa:** carbón y morado profundo con detalles cálidos; preferido para reflexión, silencio y descanso.
- **Tradición viva:** morado, tonos litúrgicos cálidos y dorado; preferido para oraciones y contenido litúrgico cuando exista contexto suficiente.

El ambiente automático será solo una sugerencia inicial. Nunca alterará el texto ni la tradición religiosa del contenido.

## 4. Arquitectura

El sistema se implementará como un módulo autocontenido en `lib/features/sharing/`.

### 4.1 Modelo normalizado

`ShareContent` será un objeto inmutable con los datos necesarios para compartir:

- `title`;
- `body`;
- `reference` opcional;
- `kind`: versículo, oración, salmo, misión o reflexión;
- `tradition` opcional;
- `liturgicalColor` opcional;
- `sourceLabel` opcional y solo para metadatos internos;
- `shareCaption` opcional para adaptar el texto que acompaña las imágenes.

Las pantallas no decidirán tamaños, fondos ni saltos de página. Solo construirán este modelo y abrirán el compositor.

### 4.2 Resolución de estilo

`ShareStyleResolver` recibirá `ShareContent` y devolverá el ambiente inicial. La resolución será determinista, local y comprobable. Usará `liturgicalColor` únicamente cuando esté disponible y validado; en los demás casos se basará en `kind`, no en análisis remoto ni IA.

### 4.3 Paginación

`SharePaginator` recibirá contenido, formato y métricas tipográficas. Sus reglas serán:

- conservar párrafos completos cuando quepan;
- dividir primero por saltos de párrafo y luego por oraciones;
- dividir por palabras solo como último recurso;
- no cortar palabras, referencias ni signos unidos al texto;
- reservar espacio para marca, referencia y numeración;
- usar un tamaño tipográfico dentro de un rango legible definido por formato;
- crear una página adicional antes de reducir el texto por debajo del mínimo;
- devolver siempre todo el contenido en el mismo orden.

El paginador producirá una lista de `SharePage`. Un versículo breve producirá normalmente una sola página.

### 4.4 Representación y exportación

`ShareCard` será el único widget responsable de dibujar una página. El compositor mostrará ese mismo widget dentro de un `RepaintBoundary`, y `ShareCardRenderer` lo exportará a PNG con las dimensiones exactas del formato. Así, la vista previa y el archivo final no tendrán composiciones distintas.

`ShareExporter` coordinará:

- creación de uno o varios PNG en un directorio temporal;
- apertura de la hoja nativa mediante `share_plus`;
- inclusión de un mensaje con la referencia, una invitación breve y la URL real de Google Play;
- guardado explícito en la galería mediante una integración compatible con MediaStore;
- copia de texto, referencia y enlace al portapapeles;
- limpieza de temporales después de terminar o al superar su tiempo de vida.

El enlace oficial será:

`https://play.google.com/store/apps/details?id=com.ozcorp.verbum`

No se incluirá la búsqueda genérica de App Store mientras Verbum no tenga una URL pública real en esa tienda.

### 4.5 Pantalla de composición

`ShareComposerScreen` recibirá un `ShareContent`. Al abrirse:

1. resolverá el ambiente inicial;
2. seleccionará 4:5;
3. paginará el texto;
4. mostrará la primera página y un indicador si existen más;
5. permitirá recorrer páginas y ambientes;
6. volverá a paginar al cambiar de formato;
7. exportará todas las páginas al pulsar compartir o guardar.

Mientras se exporta, las acciones quedarán deshabilitadas y mostrarán progreso. Cerrar o cancelar no modificará el contenido original.

## 5. Integración y alcance

Se sustituirán las llamadas directas de contenido espiritual por una fachada única, inicialmente expuesta desde `ShareService`, para no exigir una migración simultánea insegura.

Entradas incluidas:

- versículos y lectura bíblica;
- contenido y misiones de Hoy;
- favoritos;
- lectores de oraciones generales y tradicionales;
- oraciones por intención y emoción;
- salmos, categorías y novenas;
- recorridos espirituales y lecturas relacionadas.

Quedan fuera:

- invitaciones a comunidades y transmisiones en vivo;
- publicaciones creadas por usuarios;
- enlaces profundos a contenido individual;
- selección de fotos personales;
- código QR;
- cambios al contenido, traducciones bíblicas, suscripciones, chat con IA o Google Play Billing.

## 6. Errores y recuperación

- Cancelar la hoja nativa no se considerará un error.
- Si una imagen no puede renderizarse, se conservará la pantalla y se ofrecerá **Reintentar**.
- Si compartir imágenes falla, se ofrecerá compartir el texto y enlace como alternativa explícita.
- Si guardar falla por permiso, almacenamiento o servicio del sistema, se explicará la causa en lenguaje simple y se conservará la opción de compartir.
- Una página no exportada impedirá compartir el conjunto incompleto; nunca se enviarán silenciosamente solo algunas páginas.
- El borrado de temporales será tolerante a fallos y no bloqueará la interfaz.
- Los fondos y fuentes estarán empaquetados localmente. La falta de conexión no impedirá componer ni exportar.

## 7. Accesibilidad y adaptabilidad

- La pantalla respetará `SafeArea`, navegación por teclado/lector de pantalla y objetivos táctiles mínimos.
- Los controles tendrán etiquetas semánticas y no dependerán únicamente del color.
- La interfaz se adaptará a anchos pequeños y escalado de texto sin `overflow`.
- La tarjeta exportada tendrá dimensiones fijas, pero respetará un rango tipográfico legible y paginará cuando sea necesario.
- Cada ambiente tendrá contraste suficiente entre texto y fondo.
- La ventana se integrará con modo claro y oscuro; el archivo exportado conservará su ambiente elegido independientemente del tema del sistema.

## 8. Pruebas

### 8.1 Automatizadas

- pruebas unitarias para la selección de ambiente;
- pruebas unitarias de paginación con textos vacíos, breves, extensos, múltiples párrafos, tildes, comillas y palabras largas;
- comprobación de que concatenar las páginas reconstruye todo el texto sin pérdidas;
- pruebas de widgets para 1:1, 4:5 y 9:16;
- pruebas de widgets con pantalla estrecha, escalado de texto y modo oscuro;
- pruebas de estados de carga, error, reintento y múltiples páginas;
- pruebas de la fachada para confirmar que cada punto de entrada construye el `ShareContent` correcto;
- pruebas del mensaje compartido para impedir que reaparezca la URL genérica de App Store.

### 8.2 Verificación manual

- compartir un versículo corto y una oración de varias páginas mediante WhatsApp;
- abrir el selector de Instagram y comprobar el PNG en publicación e historia;
- compartir mediante otra aplicación desde la hoja nativa;
- guardar imágenes y verificarlas en la galería;
- copiar y pegar texto, referencia y enlace;
- cancelar cada flujo sin mensajes de error;
- repetir sin conexión;
- revisar Android en pantalla pequeña, pantalla grande, tema claro y oscuro;
- confirmar que no hay texto cortado, deformado, borroso ni fuera del área segura.

## 9. Criterios de aceptación

La entrega estará completa cuando:

1. todas las entradas incluidas abran el mismo compositor;
2. las tres dimensiones produzcan PNG correctos;
3. los textos largos conserven el 100 % de su contenido en páginas ordenadas;
4. compartir múltiples imágenes funcione mediante la hoja nativa;
5. guardar y copiar funcionen o muestren una recuperación clara;
6. el logotipo real y el lenguaje visual aprobado estén presentes;
7. la URL compartida corresponda al paquete `com.ozcorp.verbum`;
8. no exista referencia activa a la búsqueda genérica de App Store;
9. las pruebas automatizadas, `flutter analyze` y una compilación Android de depuración terminen correctamente;
10. no se genere un AAB de producción, no se cambie la firma y no se modifique la versión de la aplicación.

## 10. Respaldo previo

Antes de comenzar la implementación se creó:

- etiqueta Git: `backup/pre-share-composer-2026-09-22`, apuntando a `7cd27db`;
- bundle verificado: `D:\Documentos\OZCorp\Verbum_Backups\verbum-pre-share-composer-2026-09-22.bundle`.

Este respaldo representa el estado estable anterior al compositor y permite restaurar el historial completo del repositorio.
