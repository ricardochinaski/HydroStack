# Estado actual de Firebase

Esta fase documenta la integración existente; no cambia proyectos, credenciales, reglas ni configuración de Firebase.

## Inicialización

La app llama a `Firebase.initializeApp()` al arrancar. En Android espera la configuración local `android/app/google-services.json`. Si Firebase no se inicializa, `firebaseReady` queda desactivado y la app usa servicios mock donde están implementados.

El archivo histórico `docs/legacy/firebase/FIREBASE_SETUP.md` no es la fuente vigente: menciona un package name distinto del `applicationId` Android confirmado. La configuración real debe auditarse en una fase posterior.

## Firebase Auth

Uso confirmado en `apps/mobile/lib/services/firebase_auth_service.dart`:

- correo y contraseña;
- registro por correo y contraseña;
- Google Sign-In;
- lectura del usuario actual y cambios de sesión.

Tras autenticarse, el servicio crea o consulta el perfil `usuarios/{uid}` en Firestore.

## Cloud Firestore

Uso confirmado en los servicios de autenticación y datos de usuario:

| Ruta | Datos observados |
| --- | --- |
| `usuarios/{uid}` | uid, email, displayName, mode, deviceId y timestamps |
| `usuarios/{uid}/huerta/config` | nombre, capacidad, estado/ID del controlador y plantas |
| `usuarios/{uid}/cosechas/{id}` | planta, gramos, fecha y nota |

El catálogo de plantas, las lecturas de sensores obtenidas por `FirestoreService` y las alertas siguen usando datos mock. La telemetría en vivo real no se guarda en Firestore desde la app: se consume desde RTDB.

## Realtime Database

Contrato confirmado entre app y firmware:

| Ruta | Escritor | Lector / uso |
| --- | --- | --- |
| `dispositivos/{deviceId}/telemetria` | ESP8266 | app Flutter |
| `dispositivos/{deviceId}/info` | ESP8266 | información de arranque; no se confirmó consumo en la app |
| `dispositivos/{deviceId}/comandos` | app Flutter | ESP8266, que reenvía por UART |
| `dispositivos/{deviceId}/camara` | ESP32-CAM | no se confirmó consumo en la app |

Los comandos sostenidos son `luz` y `auxiliar`. `bomba` y `nutrientes` son momentáneos: el gateway los restablece a `false` después de reenviarlos.

## Firebase Storage

El firmware ESP32-CAM usa Firebase Storage para subir JPEG bajo `capturas/` y construye la URL de la última foto. La aplicación Flutter no declara `firebase_storage` ni consume de forma confirmada esas capturas.

## Configuración pendiente

- Verificar la coherencia entre `applicationId`, namespace, package name registrado y documentación histórica.
- Confirmar proyecto y entornos Firebase usados para desarrollo y producción.
- Definir un mecanismo de configuración de firmware que no dependa de editar archivos fuente.
- Confirmar el contrato de consumo de la cámara desde la aplicación.

## Pendientes de auditoría de seguridad

- Ownership de dispositivos: comprobar que cada usuario solo pueda operar dispositivos que le pertenecen.
- Reglas RTDB: revisar lectura/escritura de telemetría, comandos, información y cámara.
- Reglas Storage: restringir subidas y lecturas de capturas por dispositivo/usuario.
- Provisioning: definir alta, vinculación, revocación y transferencia de dispositivos.
- Autenticación del firmware: sustituir el esquema de token legacy por una estrategia apropiada para IoT.
- Separación dev/prod: usar proyectos, credenciales y datos claramente separados.
