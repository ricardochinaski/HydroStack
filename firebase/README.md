# Firebase

HydroStack versiona la base de seguridad de Firebase en este directorio.

## Archivos

- `firestore.rules`: perfiles privados y ownership canónico en `devices/{deviceId}`.
- `database.rules.json`: autorización RTDB mediante `deviceAccess/{uid}/{deviceId}`.
- `storage.rules`: aislamiento futuro de medios bajo `devices/{deviceId}/...`.
- `firebase.json`: configuración local de Emulator Suite para estas reglas.
- `tests/rules.test.mjs`: pruebas de aislamiento y prevención de self-claim.

La fuente de verdad de ownership es Firestore `devices/{deviceId}.ownerUid`. `deviceAccess` es una proyección derivada para enforcement en RTDB y no puede ser escrita por clientes.

## Tests

Desde `firebase/tests/`:

```bash
npm install
npm test
```

Los tests necesitan Node.js, Java y Firebase Emulator Suite (`firebase-tools`). No usan credenciales ni un proyecto Firebase de producción; el project ID de pruebas es `hydrostack-rules-test`.

## Seguridad

No agregar aquí:

- `google-services.json`;
- `GoogleService-Info.plist`;
- `.env`;
- claves privadas;
- tokens legacy;
- credenciales WiFi.

Consulta [`docs/firebase.md`](../docs/firebase.md) para el contrato completo y [`docs/device-provisioning.md`](../docs/device-provisioning.md) para identidad/claim.
