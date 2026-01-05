# Configuración de GROQ_API_KEY como Firebase Secret

## Comando para setear el secret

```bash
firebase functions:secrets:set GROQ_API_KEY
```

Este comando te pedirá que ingreses el valor del secret de forma interactiva.

**Alternativa (no recomendada para producción):**
```bash
echo "tu-api-key-aqui" | firebase functions:secrets:set GROQ_API_KEY
```

## Verificar que el secret está configurado

```bash
firebase functions:secrets:access GROQ_API_KEY
```

## Notas importantes

1. **Después de setear el secret**, debes **redesplegar las funciones**:
   ```bash
   cd api
   npm run deploy
   ```

2. El secret se lee automáticamente en la función `chatWithGroq` usando `defineSecret()`.

3. Si el secret no está configurado, la función lanzará un error `failed-precondition` con el mensaje "GROQ_API_KEY missing".

4. Los secrets son más seguros que las variables de entorno porque:
   - No aparecen en los logs
   - Se encriptan en reposo
   - Solo están disponibles en las funciones que los declaran explícitamente

