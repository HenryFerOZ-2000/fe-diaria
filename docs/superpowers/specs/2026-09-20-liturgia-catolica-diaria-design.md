# Diseño: liturgia católica diaria en Verbum

Fecha: 2026-09-20

## 1. Objetivo

Incorporar a Verbum una experiencia católica diaria real, comprensible y trazable, utilizable desde cualquier país y con Ecuador como primer territorio de revisión editorial. La app debe indicar la celebración del día, el tiempo y color litúrgicos, el rango de la celebración y sus ciclos, sin presentar como oficial ningún contenido que no haya sido verificado o licenciado.

El resultado debe sentirse integrado en la pantalla **Hoy**, funcionar sin conexión, respetar la tradición elegida por el usuario y permitir añadir calendarios nacionales, lecturas y oraciones litúrgicas sin reescribir la pantalla principal. El país, el idioma y la zona horaria se resolverán en segundo plano para que el usuario no tenga que comprender la estructura de calendarios eclesiales.

## 2. Alcance de esta primera entrega

### Incluido

- Calendario Romano General para cada fecha, en español.
- Capa regional de las Américas cuando exista respaldo verificable.
- Detección inicial de país, idioma y zona horaria a partir de la configuración del dispositivo, sin GPS ni permiso de ubicación.
- Preferencia editable de calendario local, separada del idioma de la interfaz y de la tradición cristiana. Ecuador será la primera opción nacional, siempre opcional dentro de la tradición católica.
- Fallback mundial al Calendario Romano General cuando no exista un paquete nacional verificado.
- Celebración principal y memorias opcionales.
- Tiempo litúrgico, color, rango, ciclo dominical A/B/C, ciclo ferial I/II y semana del salterio cuando la fuente los provea.
- Tarjeta compacta en **Hoy**, visible únicamente para la tradición católica.
- Pantalla de detalle del día litúrgico.
- Fuente, alcance territorial y fecha de actualización visibles.
- Datos empaquetados para funcionar sin conexión.
- Herramienta reproducible para regenerar y auditar los años publicados.
- Pruebas de fechas móviles, precedencia, zonas horarias y filtrado por tradición.

### No incluido todavía

- Textos completos de las lecturas de la misa.
- Texto completo de la colecta, antífonas, Misal o Liturgia de las Horas.
- Biografías extensas de santos tomadas de terceros.
- Calendarios propios nacionales o diocesanos mientras no exista para cada territorio una fuente autorizada y comprobable.
- Notificaciones, widgets o contenido de pago asociados a la liturgia; serán fases posteriores.

Las exclusiones son deliberadas. Las traducciones litúrgicas y bíblicas modernas pueden requerir autorización. La primera entrega mostrará metadatos y referencias verificables, no copiará textos protegidos.

## 3. Investigación y decisiones

### Fuentes y derechos

- La [Conferencia Episcopal Ecuatoriana](https://www.conferenciaepiscopal.ec/red-pastoral-de-doctrina/liturgia.html) mantiene una Comisión Episcopal de Liturgia y publica subsidios puntuales, pero no se encontró una fuente pública estable, estructurada y con permiso de redistribución para todo el calendario ecuatoriano diario.
- [Liturgical Calendar API](https://github.com/Liturgical-Calendar/LiturgicalCalendarAPI) usa fuentes eclesiales oficiales y licencia Apache 2.0. Su catálogo operativo de calendarios nacionales no incluye Ecuador actualmente, y el calendario general no ofrece una salida completa en español apta para uso directo en la app.
- [Romcal](https://github.com/romcal/romcal) implementa las reglas del Calendario Romano, tiene licencia MIT y dispone de localización española en su rama actual. No ofrece un propio nacional de Ecuador.
- Los textos completos de leccionarios y misales no se asumirán reutilizables. La [política de permisos de USCCB](https://www.usccb.org/offices/new-american-bible/permissions) sirve como evidencia de que incluso conferencias episcopales requieren licencias para reproducir sus traducciones; para Ecuador se solicitará autorización a la autoridad correspondiente antes de incluir esos textos.

### Referentes de producto

- [Universalis](https://universalis.com/n-apps.htm) separa calendario, información del día, lecturas, misa y oficio, y ajusta traducciones según el calendario local.
- [iBreviary](https://www.ibreviary.org/en/ios-ipad/android.html) descarga un día o una semana y conserva el contenido en el dispositivo.
- [Hallow](https://hallow.com/landing/) convierte el Evangelio diario en una experiencia de oración guiada, en lugar de presentar únicamente un bloque de texto.
- [Hallow](https://help.hallow.com/en/articles/9650908-overview-of-the-mobile-app) concentra el valor diario en Inicio y mantiene el idioma como una preferencia editable; no exige que el usuario configure manualmente un calendario antes de empezar.
- [Bible Chat](https://play.google.com/store/apps/details?id=com.basmo.BibleChat) presenta un recorrido diario lineal —Escritura, reflexión y oración—, además de widget y calendario cristiano. Verbum adopta la claridad del recorrido, no su acumulación completa de funciones.

Verbum adoptará cuatro ideas: separar los tipos de contenido, hacer visible el alcance local de la fuente, ofrecer una experiencia diaria breve con acceso a profundidad opcional y mantener la personalización territorial fuera del camino principal. La meta no es igualar el volumen de funciones de Hallow o Bible Chat, sino facilitar la práctica diaria con menos decisiones.

### Alternativas evaluadas

1. **Consumir una API pública en cada apertura.** Es rápida de integrar, pero crea dependencia de red y disponibilidad, no resuelve Ecuador ni el español completo y puede cambiar sin control. Descartada como fuente principal.
2. **Generar activos locales a partir de una biblioteca abierta fijada a una versión o commit.** Permite auditar el resultado, funciona sin conexión y evita cambios inesperados. Es la opción recomendada.
3. **Mantener manualmente todas las fechas y reglas en Dart.** Reduce dependencias, pero duplica reglas complejas de precedencia y aumenta mucho el riesgo de errores. Descartada.

## 4. Modelo de confianza del contenido

Cada día litúrgico conservará metadatos de procedencia:

- `sourceId`: identificador estable de la fuente.
- `sourceName` y `sourceUrl`.
- `sourceLicense`.
- `calendarScope`: `generalRoman`, una región amplia como `americas`, un país ISO 3166-1 como `EC` o, en el futuro, una diócesis identificada.
- `authorityStatus`: `openEcclesialSource`, `officialLicensed` o `pendingReview`.
- `generatedAt` y `sourceRevision`.
- `reviewedAt` y `reviewNotes` para la revisión editorial.

La interfaz no usará la palabra “oficial” salvo cuando exista autorización documental. Cuando no exista un paquete nacional verificado, mostrará **Calendario Romano General · país: Ecuador** —o el país elegido— y explicará que los propios nacionales o diocesanos no están incluidos. Esta limitación no se repetirá de forma invasiva en cada apertura; quedará disponible en el detalle de fuente.

Si una conferencia episcopal autoriza una fuente nacional, se añadirá como una capa con precedencia sobre el calendario general, sin sustituir ni modificar silenciosamente el origen de los datos. Cada capa conservará su país, revisión y autoridad.

### Perfil internacional sin fricción

Verbum mantendrá separadas cuatro preferencias:

- **idioma de la interfaz**: texto de navegación y contenido editorial disponible;
- **tradición cristiana**: católica, evangélica o cristiana general;
- **país del calendario**: territorio cuyas celebraciones locales se aplican cuando exista una fuente verificada;
- **zona horaria**: determina cuándo comienza el día del usuario.

En el primer inicio solo se pedirá la tradición, como ya hace el flujo actual. Idioma, país y zona horaria se propondrán desde el dispositivo. No se solicitará GPS ni se añadirá otra pantalla de onboarding.

Cuando el usuario elija la tradición católica y el dispositivo indique Ecuador, el perfil propondrá **Calendario católico: Ecuador**. Esta selección permitirá aplicar el paquete ecuatoriano cuando esté verificado; el usuario podrá cambiarla en cualquier momento por **Calendario Romano General**. Ecuador no aparecerá como una cuarta tradición religiosa.

Si el paquete ecuatoriano aún no existe, está incompleto o no supera la validación, la selección se conservará pero el contenido efectivo procederá del Calendario Romano General. La interfaz explicará el fallback en la fuente sin mostrar un error ni prometer cobertura local inexistente.

El país no cambiará automáticamente durante un viaje. Se conservará el territorio elegido para evitar que el contenido religioso cambie por roaming o una estancia temporal. El usuario podrá activar manualmente otro país desde Configuración.

Para la tradición evangélica no se inventará un calendario litúrgico nacional universal. El país solo podrá afectar idioma, traducciones disponibles y contenido editorial legítimamente localizado; el recorrido bíblico diario seguirá siendo propio de esa tradición.

### Separación de tradiciones y nombre divino

- El módulo litúrgico se resolverá únicamente para la tradición católica. No se mostrará, recomendará ni usará como sustituto para usuarios evangélicos o generales.
- Los contenidos editoriales y litúrgicos católicos emplearán normalmente **Dios** o **Señor**. El [Catecismo de la Iglesia Católica, 206-209](https://press.vatican.va/archive/catechism_sp/p1s2c1p1_sp.html) explica que, en la lectura de la Escritura, YHWH se sustituye por “Señor”; la directiva para la liturgia dispone el mismo criterio.
- Una cita bíblica conservará literalmente la traducción identificada. Por ello, **Jehová** puede aparecer dentro de la RV1909, pero la app no reemplazará automáticamente “Jehová” por “Señor” ni modificará el texto bíblico.
- Ningún contenido católico será el fallback de un catálogo evangélico ausente. Ante datos evangélicos inválidos o faltantes, se mostrará un estado seguro de contenido no disponible.
- La auditoría doctrinal y editorial completa de la experiencia evangélica es un proyecto hermano con especificación propia. Este módulo solo garantiza que la nueva liturgia no atraviese esa frontera.

## 5. Arquitectura

El nuevo subsistema vivirá en `lib/features/liturgy/` y no dentro de `home_screen.dart`.

### Dominio

- `LiturgicalDay`: fecha civil, celebración principal, opciones, tiempo, colores, rango, ciclos y procedencia.
- `LiturgicalCelebration`: clave estable, nombre, rango y prioridad.
- `LiturgicalSource`: alcance, licencia, revisión y URL.
- `CalendarProfile`: idioma, tradición, código de país, zona horaria, selección de calendario y origen de cada valor (`deviceDefault` o `userSelected`).
- `CalendarSelection`: `generalRoman` o `country(<ISO>)`. En la primera entrega, `country(EC)` es la única selección nacional prevista y nunca altera el valor de `FaithTradition`.
- `CalendarRegionResolver`: normaliza la región del dispositivo, aplica la selección persistida y decide qué paquetes verificados pueden superponerse.
- Enums internos para tiempo, color, rango y estado de autoridad. La UI no dependerá de cadenas recibidas de una fuente externa.

### Datos

- `assets/liturgy/general_roman_es_2025_2035.json`: instantánea base compacta y revisada, válida como fallback internacional. El rango cubre la versión actual y evita que la función caduque pronto. Se regenerará y auditará al menos una vez al año para incorporar decretos o correcciones recientes.
- `assets/liturgy/countries/<ISO>_es_YYYY_YYYY.json`: paquetes nacionales opcionales que solo existirán después de una verificación editorial y documental. La ausencia de un archivo de país es un estado válido.
- `LiturgyLocalDataSource`: carga una sola vez el activo, valida versión/esquema y resuelve una fecha por clave `yyyy-MM-dd`.
- `LiturgyRepository`: interfaz que oculta el formato del activo y permitirá añadir una fuente remota o calendario nacional después.
- `tools/generate_liturgical_calendar/`: generador de desarrollo basado en un commit exacto y registrado de Romcal, nunca en una rama móvil. Node no será una dependencia en tiempo de ejecución de Flutter.
- `tools/audit_liturgical_calendar.*`: comprueba cobertura continua, duplicados, valores permitidos, fechas móviles conocidas y metadatos de licencia.

### Aplicación

- `LiturgyService.today(...)`: usa la zona horaria efectiva del `CalendarProfile`, no la hora UTC ni una zona fija de Ecuador.
- `LiturgyService.forDate(...)`: permite navegar a ayer/mañana y futuras funciones de calendario.
- El servicio recibe un reloj y un repositorio inyectables para que las pruebas no dependan de la fecha real.
- `LiturgyService` resuelve las capas en orden: Calendario Romano General, región amplia verificada, país verificado y, en el futuro, diócesis. La capa más específica puede sustituir o añadir celebraciones, pero nunca elimina los metadatos de procedencia.

### Presentación

- `TodayLiturgyCard`: tarjeta compacta y reutilizable.
- `LiturgyDayScreen`: detalle con celebración, tiempo, rango, color, ciclos, opciones y fuente.
- `LiturgySourceSheet`: explicación breve del origen, licencia y alcance territorial.

`HomeScreen` solo decidirá si insertar la tarjeta y navegar al detalle. No parseará datos ni calculará fechas litúrgicas.

## 6. Flujo de datos

1. Al inicializar **Hoy**, la app obtiene la tradición validada de `StorageService`.
2. Si no es católica, no solicita ni muestra liturgia católica.
3. Para una tradición católica, `CalendarRegionResolver` obtiene el perfil persistido o propone país, idioma y zona horaria desde el dispositivo. En Ecuador propone `country(EC)`; fuera de Ecuador mantiene el Calendario Romano General salvo selección manual disponible.
4. `LiturgyService` calcula la fecha civil en la zona horaria efectiva y obtiene el día del Calendario Romano General.
5. Si hay una capa regional o nacional verificada para el país elegido, el repositorio la superpone y conserva su procedencia.
6. La tarjeta muestra la celebración principal y el tiempo/color.
7. Al tocarla, la pantalla de detalle recibe el objeto ya resuelto; no repite carga ni llamadas de red.
8. La fuente y el alcance están disponibles desde el detalle y desde la pantalla global de fuentes de contenido.

No se añadirá una llamada de red al arranque. Cuando exista un calendario nacional autorizado, se podrá empaquetar o descargar por año, validar, guardar y superponer sobre la instantánea general.

## 7. Experiencia de usuario

### Tarjeta en Hoy

Se ubicará después de la tarjeta de racha y antes de “Tu camino de hoy”. Mantendrá una altura contenida para no desplazar las misiones esenciales.

Contenido:

- etiqueta `HOY EN LA IGLESIA`;
- nombre de la celebración principal, máximo dos líneas;
- tiempo y rango, por ejemplo `Tiempo ordinario · Memoria`;
- punto o franja de color litúrgico con contraste accesible;
- acción `Ver el día`.

El color litúrgico será un acento, nunca el fondo completo ni el único portador de significado. Para blanco se usará marfil con borde; para verde, rojo, morado y rosa se elegirán tonos compatibles con la paleta actual y contraste WCAG adecuado.

### Pantalla de detalle

- Encabezado sereno con fecha y acento litúrgico.
- Celebración principal y, cuando corresponda, memorias opcionales claramente separadas.
- Bloque “El día litúrgico”: tiempo, rango y ciclos.
- Bloque “Para vivir hoy”: enlace a la oración devocional existente de Verbum, etiquetada como tal y no como colecta oficial.
- Bloque “Fuente y alcance” con enlace y fecha de revisión.

La pantalla no mezclará una oración generada/editorial de Verbum con el texto oficial de la liturgia. La relación será explícita: “Oración devocional sugerida para hoy”.

### Configuración internacional

La sección **Idioma y tradición** mostrará idioma, tradición y traducción bíblica. Solo cuando la tradición sea católica añadirá la fila **Calendario católico**, con las opciones **Ecuador** y **Calendario Romano General**. No se mostrarán controles litúrgicos a usuarios evangélicos o generales. La zona horaria seguirá al dispositivo salvo que el sistema no entregue una válida; no se expondrá como ajuste avanzado en esta primera entrega.

Para un usuario católico ecuatoriano, la fila se presentará como `Ecuador · recomendado para ti` hasta que la cambie. Si no hay calendario nacional verificado, una explicación secundaria dirá `Contenido local aún no disponible; se usa el Calendario Romano General`; no se mostrará un error ni se bloqueará el contenido.

El recorrido principal de **Hoy** seguirá siendo corto: **Palabra → reflexión breve → oración**. La liturgia aporta contexto a ese recorrido, pero no crea una segunda lista de tareas ni otro onboarding.

## 8. Estados y errores

- **Fecha fuera del rango empaquetado:** ocultar la tarjeta y registrar diagnóstico; nunca inventar el día ni mostrar el último día como si fuera hoy.
- **Activo ausente o corrupto:** mostrar el resto de **Hoy** normalmente. La liturgia no puede dejar la pantalla en blanco.
- **Campo opcional ausente:** omitir solo esa línea.
- **Tradición no católica:** no mostrar la tarjeta ni lenguaje católico sustitutivo.
- **Cambio de día con la app abierta:** refrescar al cambiar la fecha local, no a una hora fija como las 09:00.
- **Cambio de tradición:** invalidar la vista y recalcular visibilidad.
- **País sin paquete nacional:** usar el Calendario Romano General y mostrar el alcance real en la fuente; nunca inferir celebraciones locales.
- **Ecuador elegido con paquete pendiente o inválido:** conservar la preferencia, desactivar únicamente la superposición local y utilizar el Calendario Romano General.
- **Región del dispositivo vacía o desconocida:** usar el país guardado; si tampoco existe, usar `generalRoman` sin etiqueta territorial falsa.
- **Zona horaria no disponible:** usar la zona horaria local que exponga el sistema y registrar el fallback sin datos personales.

Los errores se registrarán sin datos personales. La UI no mostrará trazas técnicas.

## 9. Verificación editorial y técnica

### Pruebas unitarias

- Domingo de Pascua para varios años.
- Miércoles de Ceniza, Semana Santa, Ascensión, Pentecostés, Corpus Christi y Sagrado Corazón.
- Inicio de Adviento y cambio de ciclos A/B/C e I/II.
- Precedencia de solemnidad, fiesta, memoria y feria.
- Color y tiempo permitidos.
- Fecha local cerca de medianoche en `America/Guayaquil`, `America/New_York` y `Europe/Madrid`.
- Detección inicial de país sin GPS, persistencia de una selección manual y estabilidad durante viajes.
- Ecuador se recomienda únicamente para tradición católica y nunca aparece como una tradición independiente.
- El usuario puede alternar entre Ecuador y Calendario Romano General sin perder progreso ni reiniciar el onboarding.
- Fallback al Calendario Romano General para un país sin paquete verificado.
- Precedencia correcta de general → región → país y conservación de la fuente efectiva.
- Ausencia segura fuera del rango o ante JSON inválido.
- Visibilidad exclusiva para tradición católica.
- Terminología católica `Dios/Señor` y conservación literal de `Jehová` dentro de citas RV1909.
- Ausencia de fallback católico cuando la tradición sea evangélica.

### Auditoría del activo

- Una entrada por cada fecha entre 2025-01-01 y 2035-12-31.
- Claves estables y sin celebraciones duplicadas.
- Ningún valor desconocido de rango, color o tiempo.
- Fuente, licencia, revisión y revisión del generador presentes.
- Avisos de terceros y texto de la licencia MIT de Romcal incluidos en la aplicación o en sus avisos legales.
- Comparación de una muestra anual con documentos de la Santa Sede y de la Conferencia Episcopal Ecuatoriana.

### Pruebas de interfaz

- Pantallas pequeñas, fuente grande y modo oscuro.
- Nombres largos sin desbordamiento.
- Blanco litúrgico perceptible sobre fondos claros.
- **Hoy** continúa visible si falla el módulo.
- Navegación y regreso conservan el progreso de las misiones.
- Configuración con país e idioma largos sin desbordamiento.

## 10. Criterios de aceptación

- Un usuario católico en cualquier país ve sin conexión el día correcto del Calendario Romano General y puede comprobar el alcance real de la fuente.
- Un país con paquete nacional verificado aplica su capa; uno sin paquete continúa funcionando sin mensajes alarmantes ni datos inventados.
- Idioma, tradición, calendario católico y traducción bíblica son independientes y editables desde una sola sección; el calendario solo aparece cuando corresponde.
- En un dispositivo ecuatoriano, la tradición católica recomienda Ecuador sin añadir una pantalla al onboarding; el usuario puede elegir Calendario Romano General.
- La app no solicita ubicación ni cambia el país religioso automáticamente durante un viaje.
- Un usuario evangélico/general no recibe contenido litúrgico católico.
- La app distingue celebración, oración devocional y, en el futuro, lecturas.
- Cada dato visible tiene fuente y alcance consultables.
- La app no afirma tener el calendario nacional ecuatoriano completo antes de validarlo.
- No se reproducen textos litúrgicos o bíblicos modernos sin permiso.
- Un fallo del módulo nunca vacía ni bloquea la pantalla **Hoy**.
- `flutter analyze`, pruebas unitarias y auditoría del calendario pasan antes de integrar.

## 11. Evolución posterior

1. Solicitar a la Comisión Episcopal de Liturgia de Ecuador acceso o permiso para calendario nacional, leccionario y oraciones propias; después priorizar nuevos países según usuarios reales y fuentes disponibles.
2. Añadir referencias de lecturas, separadas del texto bíblico, con su propio origen y ciclo de revisión.
3. Incluir texto completo solo con licencia o con una edición explícitamente compatible.
4. Añadir descarga de semana/mes y actualización remota firmada, siguiendo el patrón de iBreviary.
5. Reutilizar el mismo `LiturgicalDay` para widget, notificación y tarjeta compartible, sin duplicar reglas.

## 12. Decisiones explícitas pendientes de autoridad externa

Los calendarios nacionales completos y los textos litúrgicos dependen de estas decisiones. No bloquean la implementación del Calendario Romano General, pero sí deben resolverse antes de anunciar una cobertura oficial para un territorio:

- confirmación del calendario propio nacional de Ecuador y de las transferencias locales de Epifanía, Ascensión y Corpus Christi;
- permiso para reproducir el Leccionario y el Misal aprobados para Ecuador;
- proceso de revisión doctrinal/editorial y persona responsable de aprobar contenido devocional.
- lista priorizada de nuevos países basada en demanda real, no en una promesa de cobertura mundial inmediata.
