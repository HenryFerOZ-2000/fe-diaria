# Solución para Error API Exception 10 - Google Sign-In

## Problema
El error "API Exception 10" (DEVELOPER_ERROR) ocurre cuando el SHA-1 del keystore de debug no está registrado en Firebase Console.

## Solución Rápida

### Paso 1: Obtener el SHA-1 (ya lo tenemos)
Tu SHA-1 de debug es:
```
0E:EC:99:36:C2:38:CA:D4:6B:49:5E:3B:3F:8D:52:08:6C:52:40:3E
```

### Paso 2: Agregar SHA-1 en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **verbum-ef0a8**
3. Ve a **Configuración del proyecto** (ícono de engranaje)
4. En la sección **Tus aplicaciones**, encuentra tu app Android:
   - Package name: `com.ozcorp.versiculo_de_hoy`
5. Haz clic en **Agregar huella digital**
6. Pega el SHA-1:
   ```
   0E:EC:99:36:C2:38:CA:D4:6B:49:5E:3B:3F:8D:52:08:6C:52:40:3E
   ```
7. Guarda los cambios

### Paso 3: Descargar nuevo google-services.json

1. Después de agregar el SHA-1, Firebase generará un nuevo OAuth client ID
2. Descarga el nuevo `google-services.json` desde Firebase Console
3. Reemplaza el archivo en: `android/app/google-services.json`
4. **IMPORTANTE**: Espera 5-10 minutos después de agregar el SHA-1 para que los cambios se propaguen

### Paso 4: Limpiar y reconstruir

```powershell
flutter clean
flutter pub get
flutter run
```

## Verificación

Si después de seguir estos pasos aún tienes problemas:

1. Verifica que el package name coincida exactamente: `com.ozcorp.versiculo_de_hoy`
2. Asegúrate de que el SHA-1 esté en formato correcto (con dos puntos)
3. Espera unos minutos después de agregar el SHA-1
4. Verifica que el `google-services.json` esté actualizado

## SHA-1 de Release (para producción)

Si vas a publicar la app, también necesitarás agregar el SHA-1 de release:
```
7C:97:10:FD:A4:2D:4A:C6:E6:09:F1:7C:DC:8E:1E:6A:18:F1:D2:A6
```

## Notas

- El código ya está configurado con el `serverClientId` correcto
- Los mensajes de error ahora son más descriptivos
- Si el problema persiste, verifica que Firebase Authentication esté habilitado en Firebase Console

