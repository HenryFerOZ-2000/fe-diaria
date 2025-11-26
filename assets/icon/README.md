# Configuración de Ícono de la Aplicación

## Instrucciones

1. **Prepara tu imagen de ícono:**
   - La imagen debe ser un archivo PNG
   - Tamaño recomendado: **1024x1024 píxeles** (mínimo)
   - La imagen debe ser cuadrada
   - Fondo transparente recomendado para mejor resultado

2. **Coloca tu imagen:**
   - Renombra tu imagen como `icon.png`
   - Colócala en esta carpeta: `assets/icon/icon.png`

3. **Genera los íconos:**
   Una vez que hayas colocado tu imagen, ejecuta el siguiente comando en la terminal:
   ```
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Verifica la generación:**
   - Los íconos se generarán automáticamente en:
     - Android: `android/app/src/main/res/` (diversas carpetas mipmap)
     - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Notas

- Si cambias el ícono, simplemente reemplaza `icon.png` y vuelve a ejecutar `flutter pub run flutter_launcher_icons`
- El color de fondo del ícono adaptativo de Android está configurado como blanco (#FFFFFF). Si deseas cambiarlo, edita el archivo `pubspec.yaml` en la sección `flutter_launcher_icons` → `adaptive_icon_background`

