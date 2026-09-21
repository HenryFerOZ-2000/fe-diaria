# Contenido y Biblia: entrega para revisión

## Implementado

- Biblioteca local identificada como Reina-Valera 1909, con 39 libros del Antiguo Testamento y 27 del Nuevo. Las preferencias y subrayados anteriores conservan sus claves.
- Catálogo de consulta católica de 73 libros, ordenados por testamento, y tres accesos a textos que la edición presenta separadamente: adiciones griegas de Ester y Daniel, y Carta de Jeremías/Baruc 6. Cada acceso abre la publicación de la Santa Sede en el navegador. No hay una nueva Biblia católica descargada ni mezcla de traducciones.
- Pantalla «Nuestra biblioteca y sus fuentes», accesible desde Biblia y Oraciones. Explica tradiciones, ediciones, textos devocionales y fuentes, sin atribuir aprobación eclesial a Verbum.
- Procedencia desplegable en el lector de oraciones. Referencia doctrinal, edición bíblica y autoría son conceptos distintos; un texto heredado sin fuente no recibe una atribución inventada.
- Catálogo cristiano general funcional y coherencia del bloqueo de módulos exclusivamente católicos para las opciones evangélica y general.
- Padre Nuestro bíblico, Salmos 23 y 91 y las dos selecciones de promesas se resuelven desde RV1909. El Salmo 91 heredado terminaba en el versículo 11: ahora contiene los 16. La lectura rechaza pasajes incompletos en lugar de volver a la copia suelta.
- Corrección de 124 diferencias de importación en la Biblia local frente a la fuente identificada. Nueva revisión de archivo local para que las instalaciones existentes reciban el texto corregido sin eliminar sus preferencias ni el archivo anterior.
- Inicialización de SQLite compartida entre peticiones concurrentes, copia temporal antes de abrir y comprobación de referencia antes de guardar la última lectura.

## Fuente de RV1909 y contraste reproducible

Publicación: https://ebible.org/details.php?id=spaRV1909

Declaración de dominio público: https://ebible.org/spaRV1909/copyright.htm

Archivo: https://ebible.org/Scriptures/spaRV1909_vpl.zip

SHA256 de la descarga revisada: `e5c553f8044e676375e5f13719493f7f47c54b5f145cc33cb65f12eb6f4dc8e5`.

La descarga contiene 31.102 referencias, de las que 18 tienen texto vacío. Sus 31.084 registros no vacíos coinciden con los de la base local. El cotejo normaliza exclusivamente espacios y los corchetes que representan cursiva en VPL. Se adaptan los códigos de libros del proveedor a los identificadores existentes. No se incorporan palabras de otra traducción.

`tools/inspect_rv1909_source.py archivo.zip --check` exige igualdad de referencias no vacías y de texto normalizado. La opción explícita `--synchronize` solo admite el hash revisado y actualiza texto, nunca identificadores. `tools/audit_bible_content.py` verifica SQLite, libros, referencias únicas, capítulos, textos no vacíos y salmos completos.

## Consulta católica

Índice enlazado: https://www.vatican.va/archive/ESL0506/_INDEX.HTM

Canon: https://www.vatican.va/archive/catechism_sp/p1s1c2a3_sp.html (n. 120).

Se comprobaron los 76 enlaces contra el índice oficial y seis destinos representativos respondieron HTTP 200. Ver `tools/verify_catholic_links.ps1`. El contenido del sitio mantiene sus derechos; se enlaza, no se redistribuye. Las funciones locales de subrayado, búsqueda de versículos y reanudación pertenecen a RV1909; en la consulta católica se busca por nombre de libro y se lee en la web.

Se investigó Torres Amat como alternativa histórica. No se encontró y verificó una transcripción digital completa con condiciones de redistribución y fidelidad suficientes durante esta revisión; no se incorporaron bases de terceros de procedencia incierta. Una copia escaneada histórica y una transcripción digital moderna requieren comprobaciones diferentes.

## Qué no está certificado

La existencia de referencias al Compendio no certifica la redacción exacta ni los derechos de todos los textos heredados. Las fórmulas tradicionales del catálogo conservan su texto y muestran referencia de consulta; las demás no se atribuyen automáticamente a Verbum, un santo o una iglesia. El lector compartido identifica explícitamente la falta de procedencia cuando corresponde.

Por tanto, esta entrega no equivale a una auditoría doctrinal completa ni resuelve una licencia de Biblia católica offline. No se ha importado una oración litúrgica por fecha: ese módulo corresponde a la siguiente entrega del plan, con calendario nacional y fuente autorizada.

El inventario `tools/audit_prayer_catalog.py` permite localizar los catálogos JSON sin metadatos de fuente. Antes de declarar todo ese material «verificado» deben cotejarse sus versiones y documentarse sus derechos o sustituirse por contenido con procedencia comprobada. No se eliminó material heredado durante esta fase.

## Pruebas para la revisión del usuario

Validación automática: análisis Flutter sin incidencias; 13 pruebas aprobadas, incluidas siete nuevas de contenido, preferencias y pantalla pequeña con texto ampliado/teclado. Compilación APK debug completada. Cotejo de RV1909 sin diferencias tras la normalización documentada; controles estructurales de SQLite aprobados. Esto no sustituye la revisión manual del flujo completo en un dispositivo ni una validación doctrinal de las oraciones heredadas.

1. En Biblia comprobar los 39/27 libros, buscar y abrir un pasaje conocido. Revisar que la lectura anterior y los subrayados sigan presentes.
2. Abrir «Consultar la Biblia católica», buscar Tobías, Judit y Eclesiástico; revisar también las adiciones de Ester/Daniel y Baruc 6. La salida al navegador debe ser explícita.
3. En Oraciones cambiar a cristiana general y abrir Salmo 91: debe llegar al versículo 16 y declarar RV1909. Repetir con las promesas y el Padre Nuestro bíblico.
4. Desplegar «Acerca de este texto» en una oración tradicional y otra sin procedencia; comprobar que no se declaren oficiales de forma engañosa.
5. Probar sin conexión: RV1909 y las oraciones locales siguen disponibles; la consulta externa requiere conexión.

No se generará AAB, ni se publicará, ni se realizará commit/push hasta la revisión acordada.

## Continuación: integridad de los contenidos empaquetados

### Aclaración posterior del propietario: generación con IA

El 20 de septiembre de 2026 el propietario confirmó que las oraciones se generaron con IA. Esta declaración documenta el método de obtención del corpus devocional; no identifica todavía el modelo, proveedor, prompts o condiciones utilizadas. No implica cotejo doctrinal, originalidad exclusiva ni permiso sobre fórmulas preexistentes que una IA haya reproducido.

Se incorpora la etiqueta «Composición devocional · IA» en los lectores del catálogo por emoción, intención, noche, oración personalizada/categorías y las misiones de oración de mañana/noche/familia. Las fórmulas tradicionales reconocibles conservan su clasificación; las selecciones bíblicas resueltas desde RV1909 conservan su procedencia bíblica. Los lectores genéricos no atribuyen automáticamente a IA textos arbitrarios. La pantalla de fuentes explica esta separación. No se modificaron los cuerpos de las oraciones ni se declararon oficiales.

Esta aclaración sustituye el pendiente de preguntar al propietario por la procedencia general. Permanecen pendientes el cotejo de fórmulas tradicionales, la revisión editorial/doctrinal del contenido generado y la edición católica offline con condiciones comprobadas. Los inventarios de JSON sin metadatos individuales siguen siendo descriptivos de esos archivos y deben leerse junto con esta declaración; no prueban una fuente externa desconocida.

Al ampliar la revisión se detectaron problemas que no cubría la primera entrega:

- `assets/traditions/evangelical/` no estaba declarado como subcarpeta de recursos. El servicio sustituía su ausencia por el catálogo general usado para la selección católica. Se incluye explícitamente y se elimina esa sustitución entre tradiciones.
- Dos peticiones de carga simultáneas podían devolver antes de tener contenido. Ahora comparten la misma operación; el catálogo se construye en variables locales y se publica completo, incluso si se limpia la caché mientras carga.
- La caché compartía fecha y tradición entre mañana/noche. Cada entrada conserva además su propio contexto para impedir mezclas al cambiar de tradición, incluso con peticiones en vuelo. Se rechazan IDs antiguos basados en timestamps como evidencia de pertenencia a una tradición.
- Los 425 registros de `assets/data/verses.json` eran paráfrasis con libro vacío y capítulo/versículo cero. Sus copias mensuales y diez selecciones de salmos tampoco declaraban edición verificable. Se sincronizaron **860 registros en 15 archivos** con RV1909 local, manteniendo IDs, orden y referencias. Los textos anteriores se sustituyeron, no se atribuyeron a RV1909; pueden recuperarse de Git HEAD, sin que ello borre cambios de usuario.
- Cada registro sincronizado declara edición, fuente, estado de cotejo y rangos completos. Las selecciones de varios pasajes preservan sus rangos separados. `tools/sync_biblical_assets.py` comprueba por defecto; `--apply` realiza la sincronización mecánica solo después de validar todos los pasajes.
- Se corrigió `NAH` por el identificador local `NAM` en el pasaje de Nahúm 1:7 para ansiedad. El auditor ahora verifica **2.093 referencias estructuradas**, incluidas las copias de metadatos; no son 2.093 pasajes únicos.
- La información de derechos ahora es visible en el lector, y los salmos por categorías transmiten su procedencia RV1909 hasta el lector y el texto compartido.

### Inventario editorial pendiente, sin certificaciones inventadas

El inventario completo de los JSON de oraciones incluye textos cortos que antes se omitían: **610 registros y 430 huellas de texto distintas** en 14 archivos. Ninguno de esos JSON contiene URL de procedencia explícita. Las cinco selecciones bíblicas de `TraditionalPrayersService.readPrayer` sí se resuelven y atribuyen en tiempo de lectura; el inventario describe los archivos heredados, no sustituye esa resolución.

`python tools/audit_prayer_catalog.py --details` devuelve la ubicación JSON, ID/título cuando existe, huella SHA-256 y estado declarado, sin imprimir el cuerpo completo. No incluye textos incrustados en Dart ni presume que coincidencia de título pruebe autoría.

Para cerrar de verdad la revisión editorial se necesita confirmar de dónde obtuvo el propietario esos textos y qué permisos tiene, o acordar su sustitución por un corpus con derechos documentados. No se han retirado masivamente oraciones, inventado atribuciones ni presentado textos generados como fórmulas oficiales.

La investigación adicional de Torres Amat volvió a localizar escaneos históricos, no una transcripción digital completa cotejada y lista para redistribuir. No se mezclaron libros de otra edición para simular una Biblia católica. Se mantiene la consulta externa de la Santa Sede. La liturgia diaria, además, sigue necesitando elegir calendario nacional y fuente autorizada; no se puede dar esa función por implementada.

### Registro de decisiones y revisión

- Continuación en la rama de trabajo existente `chore/android-modernization`, preservando el conjunto de cambios pendientes de revisión. Sin commits ni nueva rama para no separar estos cambios de la entrega anterior.
- Se acota esta continuación a contenido/Biblia. Compartir imágenes, widgets, chat y suscripción siguen siendo entregas posteriores del plan, no se declaran completadas.
- Se reemplazan las paráfrasis presentadas como versículos por citas RV1909 completas. Consecuencia visible: lenguaje histórico y algunos textos más largos; se conservan referencias e IDs.
- Revisión independiente de código: detectó dos carreras de carga/cambio de tradición. Ambas se reprodujeron mediante pruebas fallidas y quedaron corregidas con publicación atómica del catálogo y contexto individual de caché.
- La revisión técnica no acredita derechos editoriales, doctrina, disponibilidad de enlaces externos ni funcionamiento de Firebase en dispositivo. Esas comprobaciones siguen separadas; ignorarlas podría permitir publicar contenido no autorizado o fallos exclusivos del entorno real.

Validación de esta continuación: 21 pruebas Flutter y cinco Python aprobadas. `sync_biblical_assets.py` informa cero archivos pendientes de sincronización; auditoría de referencias y SQLite aprobada. `flutter analyze` sin incidencias. `flutter build apk --debug` completado (33,9 s), archivo `build/app/outputs/flutter-apk/app-debug.apk`. Gradle conserva avisos sobre la futura migración de Kotlin integrado; no impidieron esta compilación y no se modificó el stack Android en esta etapa. No se probó el APK en dispositivo ni se generó AAB.

## Calendario litúrgico católico sin conexión

La nueva sección diaria católica usa una instantánea del **Calendario Romano General** generada con Romcal `3.0.0-dev.140`, revisión `6246bad8c548c1f2528916df40e433c1f7c97c6a`, bajo licencia MIT. El activo cubre del 1 de enero de 2025 al 31 de diciembre de 2035 (4.017 fechas) y fue generado y auditado el 20 de septiembre de 2026. La licencia se distribuye en `assets/licenses/romcal.txt`.

`assets/liturgy/manifest.json` enumera las capas nacionales permitidas. En esta entrega no existe una capa ecuatoriana verificada: elegir Ecuador conserva la preferencia y utiliza honestamente el Calendario Romano General como respaldo. Verbum no afirma incluir todos los propios nacionales de Ecuador ni calendarios diocesanos. Solo un paquete registrado como verificado podrá superponer el activo base.

La liturgia diaria se muestra exclusivamente para la tradición católica. Las tradiciones evangélica/protestante y cristiana general conservan sus recorridos bíblicos y nunca reciben contenido católico como sustitución. En el contenido editorial católico se usa normalmente **Dios** o **Señor**; las citas de RV1909 conservan literalmente su traducción, incluido **Jehová** cuando aparece en ella.

La información muestra celebración, rango, tiempo, color y ciclos; no reproduce textos completos del Misal, Leccionario ni Liturgia de las Horas. La oración presentada junto al día se identifica como sugerencia devocional, no como colecta u oración oficial. Romcal es una fuente técnica abierta y no implica aprobación eclesial de Verbum.
