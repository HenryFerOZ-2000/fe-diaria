# Firebase Functions: seedFirestore

Sistema de seed para crear datos base en Firestore (solo uso de desarrollo).

## Requisitos iniciales

- Tener instalado `firebase-tools` (`npm i -g firebase-tools`).
- Acceso al proyecto de Firebase ya configurado con Authentication y Firestore.
- Clave secreta `SEED_KEY` definida en el entorno (ej. archivo `.env`).

## Paso a paso

1. Si aún no existe la carpeta `functions`, ya está incluida aquí con TypeScript.
2. Instalar dependencias dentro de `functions`:

   ```bash
   cd functions
   npm install
   ```

3. Autenticarse y asociar el proyecto (si aplica):

   ```bash
   firebase login
   firebase use <project-id>
   # o pasar --project <project-id> en cada comando
   ```

4. Configurar la clave de seed:

   - Coloca `SEED_KEY` en tu entorno al emular o desplegar.
   - Ejemplo `.env` (no se sube a git): `SEED_KEY=coloca-una-clave-segura`

## Deploy

```bash
cd functions
npm run build
firebase deploy --only functions
```

## Function: seedFirestore

- Tipo: HTTP request (`POST`).
- URL tras deploy: `https://<region>-<project-id>.cloudfunctions.net/seedFirestore`
- Seguridad: requiere header `x-seed-key` igual a `process.env.SEED_KEY`. Si no coincide, responde 401. No usar en producción sin la clave.

### Ejemplo de ejecución (curl)

```bash
curl -X POST \
  -H "x-seed-key: <tu-clave-seed>" \
  https://<region>-<project-id>.cloudfunctions.net/seedFirestore
```

### Ejemplo en emulador

```bash
cd functions
export SEED_KEY=<tu-clave-seed>
firebase emulators:start --only functions
# Luego:
curl -X POST -H "x-seed-key: <tu-clave-seed>" http://127.0.0.1:5001/<project-id>/us-central1/seedFirestore
```

## Qué crea/actualiza

- `daily_content/{YYYYMMDD}` con:
  - `verseRef: "PSA 23:1"`, `book: "PSA"`, `chapter: 23`, `verse: 1`
  - `prayerDay`, `prayerNight` placeholders
  - `createdAt: serverTimestamp()`
- `live_posts`:
  - Si no existe hoy un doc con `text="Oración de prueba"` y `status="active"`, crea uno con `createdAt` y `endAt = now + 60s`, contadores en 0.
  - Si existe, lo actualiza (sin duplicar) y asegura métricas con incrementos 0.
- `users/TEST_UID` con `plan: "free"` y `createdAt` si no existía.

## Verificación en Firestore

Revisa las colecciones:

- `live_posts`: debería existir un documento de prueba `text="Oración de prueba"`.
- `daily_content`: documento con id `YYYYMMDD` (UTC) del día actual.
- `users`: documento `TEST_UID`.

