# 📱 Verbum

Aplicación móvil Flutter con versículos bíblicos, oraciones, devocionales, categorías espirituales y contenido católico para fortalecer la fe diaria.

## ✨ Características principales

- 📖 **Versículo del Día**: Recibe un versículo bíblico personalizado cada día
- 🙏 **Oraciones Diarias**: Oraciones de mañana y noche adaptadas a tu momento
- 💝 **Oración Personalizada**: Oraciones basadas en tu estado emocional
- 📚 **Devocionales Diarios**: Reflexiones diarias con versículos y meditaciones
- 📿 **Guía del Rosario**: Aprende a rezar el rosario paso a paso con los misterios del día
- ⛪ **Oraciones Tradicionales**: Oraciones clásicas de la tradición cristiana
- 📖 **Salmos por Categoría**: Salmos de protección, agradecimiento y consuelo
- 😊 **Cómo te Sientes Hoy**: Oraciones personalizadas según tu emoción
- 🌙 **Oraciones para Dormir**: Oraciones de paz y descanso nocturno
- 💌 **Peticiones Especiales**: Oraciones por salud, trabajo, familia y más
- 📝 **Intenciones del Día**: Guarda y reza por tus intenciones personales
- ⭐ **Santos del Día**: Conoce a los santos y sus oraciones
- 🎄 **Novena de Navidad**: Novena día a día con seguimiento de progreso
- ⭐ **Favoritos**: Guarda tus versículos y oraciones favoritas
- 🌓 **Modo Oscuro**: Interfaz adaptada para lectura nocturna
- 🔔 **Notificaciones**: Recordatorios diarios personalizables
- 🎨 **Diseño Moderno**: Interfaz elegante y profesional

## 🔧 Tecnologías usadas

- **Flutter** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **Provider** - Gestión de estado
- **Hive** - Almacenamiento local
- **Google Fonts** - Tipografías modernas (Poppins, Nunito)
- **Google Mobile Ads** - Monetización
- **Flutter Local Notifications** - Notificaciones push
- **Share Plus** - Compartir contenido
- **Audio Players** - Reproducción de audio

## 🚀 Cómo correr el proyecto localmente

### Prerrequisitos

- Flutter SDK (versión 3.9.2 o superior)
- Dart SDK
- Android Studio / Xcode (para desarrollo móvil)
- Un editor de código (VS Code o Android Studio recomendado)

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/HenryFerOZ-2000/fe-diaria.git
   cd fe-diaria
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

### Configuración adicional

- **Android**: Asegúrate de tener configurado el SDK de Android
- **iOS**: Requiere Xcode y CocoaPods instalado
- **Notificaciones**: Configura los permisos necesarios en cada plataforma

## 🔐 Inicio de sesión con Google

### Android
- Paquete de la app: `com.ozcorp.verbum` (ver `android/app/build.gradle.kts`)
- Pasos:
   1. Obtén el SHA-1 de tu keystore de debug o release:
       ```bash
       keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | grep SHA1
       ```
       Para release, usa tu `key.properties` y keystore correspondiente.

Esta debe ser agregada a la consola de firebase para que funcione. Si no registras el SHA-1 verás errores como `DEVELOPER_ERROR (code 10)` al intentar iniciar sesión.


## 🤝 Cómo colaborar

### Flujo de trabajo con Git

1. **Crear una rama para tu feature**
   ```bash
   git checkout -b feature/nombre-de-tu-feature
   ```

2. **Hacer tus cambios y commits**
   ```bash
   git add .
   git commit -m "Descripción de tus cambios"
   ```

3. **Subir tu rama a GitHub**
   ```bash
   git push origin feature/nombre-de-tu-feature
   ```

4. **Crear un Pull Request** en GitHub para revisar tus cambios

### Convenciones de código

- Usa nombres descriptivos para variables y funciones
- Comenta código complejo
- Sigue las convenciones de Flutter/Dart
- Mantén el código organizado en carpetas lógicas

## 📂 Estructura del proyecto

```
lib/
├── l10n/              # Localizaciones
├── models/            # Modelos de datos
│   ├── prayer.dart
│   ├── verse.dart
│   ├── category.dart
│   ├── emotion.dart
│   ├── devotional.dart
│   ├── psalm.dart
│   └── rosary_guide.dart
├── providers/         # Gestión de estado
│   └── app_provider.dart
├── screens/           # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── categories_screen.dart
│   ├── emotion_selection_screen.dart
│   ├── prayer_for_you_screen.dart
│   ├── settings_screen.dart
│   └── ...
├── services/          # Servicios y lógica de negocio
│   ├── verse_service.dart
│   ├── prayer_service.dart
│   ├── devotionals_service.dart
│   ├── psalms_service.dart
│   └── ...
├── theme/             # Tema y estilos globales
│   └── app_theme.dart
├── widgets/           # Componentes reutilizables
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── main_card.dart
│   ├── category_card.dart
│   ├── prayer_card.dart
│   └── ...
└── main.dart          # Punto de entrada

assets/
├── data/              # Archivos JSON con contenido
│   ├── devotionals.json
│   ├── psalms.json
│   ├── night_prayers.json
│   ├── prayers_by_emotion.json
│   ├── prayers_by_intention.json
│   ├── rosary_guide.json
│   └── saints.json
├── verses/            # Versículos bíblicos
├── prayers/           # Oraciones
└── oraciones/         # Oraciones adicionales
```

## 🖼️ Screenshots

_Próximamente: Capturas de pantalla de la aplicación_

## 📝 Licencia

Este proyecto es de uso privado. Todos los derechos reservados.

## 👨‍💻 Autor

**HenryFerOZ-2000**

---

⭐ Si este proyecto te ha sido útil, considera darle una estrella en GitHub.
