# Estado actual de Firebase

Este documento describe el contrato Firebase vigente en HydroStack después de introducir la base de identidad/ownership y el protocolo seguro de comandos v2. No cambia todavía el proyecto Firebase, la autenticación del firmware ni el provisioning físico.

## Inicialización

La app llama a `Firebase.initializeApp()` al arrancar. En Android espera la configuración local `android/app/google-services.json`. Si Firebase no se inicializa, `firebaseReady` queda desactivado y los providers que lo permiten usan implementaciones mock.

La separación estricta dev/staging/prod sigue pendiente y debe resolverse antes de producción.

## Firebase Auth

Uso confirmado en `apps/mobile/lib/services/firebase_auth_service.dart`:

- correo y contraseña;
- registro por correo y contraseña;
- Google Sign-In;
- lectura del usuario actual y cambios de sesión.

El UID autenticado es la identidad de usuario usada por el contrato de ownership y queda registrado como `requestedBy` en los comandos v2.

## Fuente de verdad del ownership

La fuente canónica es:

`devices/{deviceId}`

con un documento conceptual como:

```text
deviceId:   identificador técnico único e inmutable
ownerUid:   UID de Firebase Auth propietario
alias:      nombre visible editable por el propietario
status:     estado controlado por infraestructura confiable
claimedAt:  timestamp de claim
createdAt:  timestamp de creación
updatedAt:  timestamp de metadatos editables
```

`deviceId` identifica al hardware. No es contraseña, token ni prueba de posesión.

La app puede guardar un `preferredDeviceId` local como selector de UX, pero ese valor solo se usa después de que `DeviceService` comprueba que `devices/{deviceId}.ownerUid` coincide con el UID autenticado.

Los campos históricos `usuarios/{uid}.deviceId`, `Huerta.esp32Id`, `Huerta.esp32Connected`, `AppUser.esp32Id` y `AppUser.esp32Connected` se consideran compatibilidad legacy y no son autoridad de ownership.

## Cloud Firestore

Rutas activas:

| Ruta | Uso |
| --- | --- |
| `usuarios/{uid}` | perfil, modo y referencias legacy |
| `usuarios/{uid}/huerta/config` | configuración funcional de huerta |
| `usuarios/{uid}/cosechas/{id}` | registros de cosecha |
| `devices/{deviceId}` | identidad y ownership canónico |

`apps/mobile/lib/services/device_service.dart` es la capa responsable de consultar dispositivos, comprobar ownership y resolver el dispositivo autorizado.

### Reglas versionadas

`firebase/firestore.rules` implementa:

- acceso del usuario únicamente a su perfil y subdatos;
- lectura de `devices/{deviceId}` solo si `ownerUid == request.auth.uid`;
- creación/claim de `devices` denegada a clientes;
- `ownerUid` y `deviceId` inmutables desde cliente;
- modificación cliente limitada a `alias` y `updatedAt`;
- una referencia legacy `usuarios/{uid}.deviceId` solo puede cambiar a un dispositivo realmente propiedad de ese usuario.

El claim seguro queda bloqueado hasta incorporar infraestructura confiable de provisioning/proof-of-possession.

## Realtime Database

### Rutas generales

| Ruta | Uso |
| --- | --- |
| `deviceAccess/{uid}/{deviceId}` | proyección de autorización para Security Rules |
| `dispositivos/{deviceId}/telemetria` | telemetría publicada por gateway |
| `dispositivos/{deviceId}/info` | metadatos de arranque del gateway |
| `dispositivos/{deviceId}/comandos` | registros inmutables de comandos v2 |
| `dispositivos/{deviceId}/commandPointers` | ID vigente por actuador |
| `dispositivos/{deviceId}/commandAcks` | resultado correlacionado por commandId |
| `dispositivos/{deviceId}/camara` | metadatos legacy de cámara |

### Proyección de autorización

`deviceAccess/{uid}/{deviceId}: true`

Esta proyección existe porque el enforcement de RTDB usa datos disponibles en RTDB. Debe ser creada y eliminada únicamente por infraestructura confiable cuando cambie el ownership; el cliente no puede escribirla.

**Fuente de verdad:** Firestore `devices/{deviceId}.ownerUid`.

**Proyección derivada para enforcement RTDB:** `deviceAccess/{uid}/{deviceId}`.

Conocer únicamente un `deviceId` no concede acceso.

### Comandos v2

Cada comando se crea como registro inmutable:

```text
/dispositivos/{deviceId}/comandos/{actuator}/{commandId}
```

con:

```text
commandId
value
issuedAt
ttlMs
requestedBy
```

`issuedAt` se escribe desde Flutter con `ServerValue.timestamp`. Las reglas exigen una marca temporal cercana a `now`, el reloj del servidor RTDB, y un TTL entre 1 y 15 segundos.

Actuadores permitidos:

- `luz`;
- `auxiliar`;
- `bomba`;
- `nutrientes`.

Los registros de comando son create-only para clientes. No pueden editarse ni borrarse después de crearse.

El ID que debe procesar el gateway se publica en:

```text
/dispositivos/{deviceId}/commandPointers/{actuator}
```

El puntero solo puede referenciar un comando existente del mismo actuador cuya `requestedBy` coincida con el UID autenticado.

El resultado se publica en:

```text
/dispositivos/{deviceId}/commandAcks/{actuator}/{commandId}
```

Los clientes pueden leer esos ACK a través del acceso autorizado del dispositivo, pero no escribirlos.

El contrato completo, estados y framing UART están en `docs/commands.md`.

## Firebase Storage

`firebase/storage.rules` prepara la ruta canónica futura:

`devices/{deviceId}/...`

La lectura está permitida únicamente si Firestore confirma que el usuario autenticado posee el dispositivo. La escritura cliente está cerrada en esta fase.

La ruta legacy del firmware actual, `capturas/`, permanece cerrada por reglas. La migración de ESP32-CAM y su autenticación se realizará en una fase posterior; no se abrió Storage públicamente para mantener compatibilidad.

## Reglas y emuladores

Archivos versionados:

- `firebase/firestore.rules`
- `firebase/database.rules.json`
- `firebase/storage.rules`
- `firebase/firebase.json`
- `firebase/tests/rules.test.mjs`

La suite cubre ownership, aislamiento A/B y además el protocolo v2: creación de comandos, inmutabilidad, timestamps, TTL, identidad `requestedBy`, commandId, punteros y prohibición de ACK cliente.

Los tests deben ejecutarse en Firebase Emulator Suite antes de integrar la rama. En el entorno de edición actual no están disponibles Firebase CLI ni las dependencias instalables, por lo que no se declara un resultado de ejecución.

## Riesgos todavía abiertos

- no existe todavía backend/función confiable de claim;
- no existe sincronizador confiable Firestore → `deviceAccess`;
- el firmware sigue usando autenticación Firebase legacy y una credencial global conceptual;
- `HS-001` continúa compilado en firmware y solo se conserva en Flutter como ID manual de desarrollo;
- falta autenticación IoT por dispositivo y revocación individual;
- falta separación estricta dev/staging/prod;
- la cámara debe migrar de `capturas/` al contrato seguro por dispositivo;
- la discrepancia histórica Android/Firebase debe resolverse antes de release;
- los registros históricos de comandos y ACK aún no tienen política de retención/limpieza.
