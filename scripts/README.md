# Scripts

## Deploy de Firebase Functions (carpeta `api`)

Desde la raíz del repo:

```powershell
pwsh ./scripts/deploy_functions.ps1
```

El script reinstala dependencias en `api`, corre `npm run lint`, `npm run build`
y luego `firebase deploy --only functions`. Requiere tener `firebase-tools`
configurado y `SEED_KEY` en el entorno para probar `seedFirestore`.

## Modo seguro (no tocar Flutter)

Ejecutar verificación:

```powershell
pwsh ./scripts/safe_check.ps1
```

Crear respaldo seguro en rama `firebase-backend-safe`:

```powershell
pwsh ./scripts/safe_backup.ps1
```

Nota: necesitas `git` instalado y en el PATH para usar estos scripts.

