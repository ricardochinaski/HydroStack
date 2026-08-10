# HydroStack — System Contracts Audit

**Fecha:** 2026-08-10  
**Rama:** `audit/system-contracts`  
**Base auditada:** `main` en `ad10cf3cc60320ad53ebe48da11e4c33796666fa`  
**Alcance:** auditoría de solo lectura de Flutter, Android, Firebase, ESP8266, Arduino Mega, ESP32-CAM, UART e identidad de dispositivo.  
**Cambios funcionales:** ninguno.

## Convenciones

- **HECHO CONFIRMADO:** observable directamente en código o estructura versionada.
- **INFERENCIA:** conclusión derivada del comportamiento del código, indicada explícitamente como tal.
- **RIESGO:** impacto potencial del contrato actual.
- **RECOMENDACIÓN FUTURA:** trabajo posterior; no se implementa en esta fase.

La severidad considera un futuro uso con hardware real. Cuando una exposición depende de reglas Firebase desplegadas fuera del repositorio, se indica expresamente que la explotabilidad no puede confirmarse solo con Git.

---

# 1. RESUMEN EJECUTIVO

**HECHO CONFIRMADO**

La arquitectura activa es coherente como prototipo: Flutter usa Firestore para datos de usuario, RTDB para telemetría/comandos, un ESP8266 como gateway y un Mega 2560 como controlador de sensores/relés. El ESP32-CAM es independiente. Existe además un simulador local.

La auditoría encontró tres problemas de severidad crítica para un despliegue con más de una torre o con actuadores remotos:

1. `HS-001` está hardcodeado como identidad en el gateway, la cámara y como valor predeterminado en Flutter.
2. Los comandos momentáneos `bomba` y `nutrientes` son flags booleanos sin ID, TTL ni ACK del Mega; el gateway los reenvía y después intenta escribir `false` en RTDB.
3. El repositorio no contiene reglas RTDB/Storage/Firestore desplegables ni un contrato de ownership verificable, mientras el cliente permite escribir manualmente cualquier `deviceId`.

También se confirmaron problemas altos: fallback automático a autenticación mock, uso previsto de token legacy compartido en firmware, conversión ADC/pH incorrecta para el Mega, telemetría stale que puede publicarse con timestamp nuevo, divergencia de estados tras reinicios, firma Android release con clave debug y cámara LAN sin autenticación.

**RIESGO**

El sistema no debe considerarse listo para controlar bombas/dosificadores de forma remota en producción hasta estabilizar identidad, ownership, comandos y fail-safe.

**RECOMENDACIÓN FUTURA**

Resolver primero control-plane/ownership y seguridad física de actuadores; después branding, nuevas funciones o release.

---

# 2. RAMA

**HECHO CONFIRMADO**

- `main` fue integrado por fast-forward hasta `ad10cf3cc60320ad53ebe48da11e4c33796666fa` antes de iniciar esta auditoría.
- `audit/system-contracts` fue creada desde ese `main`.
- No se modificó `main` después de crear la rama de auditoría.

---

# 3. ARCHIVOS MODIFICADOS

**HECHO CONFIRMADO**

La única modificación intencional de esta fase es:

- `docs/audits/system-contracts-audit.md`

No se modificaron Flutter, Gradle, Firebase, firmware, pines, calibraciones, UART ni dependencias.

---

# 4. HALLAZGOS CRÍTICOS

## C-01 — Identidad global `HS-001`

**HECHO CONFIRMADO**

- `firmware/gateway-esp8266/HidroSmart_Firmware.ino`: `DEVICE_ID = "HS-001"`.
- `firmware/camera-esp32cam/HidroSmart_Cam.ino`: `DEVICE_ID = "HS-001"`.
- `SettingsState.deviceId`: valor predeterminado `HS-001`.

**INFERENCIA**

Si dos torres se flashean sin cambiar el firmware, ambos gateways publicarán en el mismo nodo y ambos leerán los mismos comandos.

**RIESGO — CRÍTICO**

- última telemetría en escribir gana;
- un comando puede accionar dos torres simultáneamente;
- `/info` y `/camara` se pisan;
- no existe aislamiento lógico por unidad.

**RECOMENDACIÓN FUTURA**

Identidad única e inmutable por hardware, separada de un alias humano, emitida durante fabricación/provisioning.

## C-02 — Comandos momentáneos sin ACK/idempotencia

**HECHO CONFIRMADO**

`bomba=true` y `nutrientes=true` se sondean cada 3 s. El ESP8266:

1. detecta `true`;
2. envía `BOMBA_ON` o `NUTRIENTES_ON` por UART;
3. intenta escribir `false` en RTDB.

El Mega convierte cada comando recibido en un pulso de 5 s y reinicia el deadline a `millis()+5000`.

**INFERENCIA**

Si el envío UART funciona pero el `setBool(..., false)` falla repetidamente, el gateway puede reenviar el mismo `true` cada 3 s. Cada recepción extiende el pulso otros 5 s.

**RIESGO — CRÍTICO**

Una falla cloud parcial puede transformar un disparo momentáneo en operación prácticamente continua de bomba/dosificador. El riesgo es especialmente relevante para nutrientes.

En la dirección opuesta, si el UART está desconectado, el gateway igualmente puede consumir el flag y resetearlo sin saber si el Mega recibió el comando.

**RECOMENDACIÓN FUTURA**

Usar comandos con `commandId`, tipo, parámetros, timestamp/TTL, estado (`pending/accepted/applied/failed`), ACK del controlador y límites locales de duty-cycle que no dependan de Firebase.

## C-03 — Ownership del dispositivo no demostrable

**HECHO CONFIRMADO**

- El repo no versiona reglas Firebase desplegables.
- El usuario puede escribir manualmente un ID en `SimuladorScreen`.
- Ese ID se guarda localmente y en `usuarios/{uid}.deviceId`.
- La app usa directamente ese ID en `dispositivos/{deviceId}`.
- No hay claim, secreto por dispositivo, challenge físico, transferencia ni revocación.
- El árbol RTDB utilizado no contiene el UID propietario dentro de su contrato observable.

**INFERENCIA**

Un cliente modificado puede seleccionar un ID distinto del propio. Si las reglas RTDB desplegadas solo exigen autenticación general, son públicas, o no verifican ownership mediante una fuente autoritativa, conocer otro ID sería suficiente para intentar leer telemetría o enviar comandos.

**RIESGO — CRÍTICO**

Control remoto entre usuarios/dispositivos. La explotabilidad efectiva no puede confirmarse porque las reglas reales de consola no están versionadas en este repositorio.

**RECOMENDACIÓN FUTURA**

Definir ownership server-side versionado y testeable antes de habilitar control remoto real.

---

# 5. HALLAZGOS ALTOS

## H-01 — Producción puede caer silenciosamente a mock

**HECHO CONFIRMADO**

`main.dart` captura cualquier excepción de `Firebase.initializeApp()` y solo pone `firebaseReady=false`. `authServiceProvider` y `firestoreServiceProvider` seleccionan implementaciones mock cuando eso ocurre.

`MockAuthService.signInWithEmail()` no valida una credencial remota: crea un usuario local a partir del email recibido.

**RIESGO — ALTO**

Una release mal configurada puede parecer operativa/autenticada aunque Firebase real no funcione.

**RECOMENDACIÓN FUTURA**

Mock permitido únicamente en builds explícitas de desarrollo; producción debe fallar de forma visible y no ambigua.

## H-02 — Credencial firmware legacy compartible

**HECHO CONFIRMADO**

Gateway y cámara declaran `FIREBASE_AUTH` como `TU_FIREBASE_LEGACY_TOKEN` y lo asignan a `signer.tokens.legacy_token`.

**INFERENCIA**

El diseño esperado es una credencial estática embebida en firmware. Si se reutiliza la misma en varias unidades, comprometer una unidad compromete el alcance completo que posea ese token.

**RIESGO — ALTO**

Blast radius amplio y rotación compleja. Además, las bibliotecas Mobizt `Firebase ESP8266 Client` / `Firebase-ESP-Client` usadas por estos firmwares están deprecadas/EOL en sus proyectos upstream y recomiendan `FirebaseClient` para soporte futuro.

**RECOMENDACIÓN FUTURA**

Adoptar identidad/autenticación por dispositivo y migrar a una biblioteca/protocolo mantenido como parte de una fase controlada.

## H-03 — Conversión ADC/pH incorrecta para Mega estándar

**HECHO CONFIRMADO**

No existe una llamada a `analogReference(...)`. El Mega usa su referencia ADC por defecto basada en AVCC; en un Mega 2560 Rev3 estándar es nominalmente 5 V. El código convierte:

`voltaje = promedio * 3.3 / 1023`

mientras `V_MIN=0.084` y `V_MAX=3.030` son tratados como voltajes.

**ANÁLISIS**

Alimentar el potenciómetro a 3.3 V limita la señal de entrada, pero no cambia por sí mismo la referencia del ADC.

Ejemplo usando AVCC nominal de 5 V:

- Voltaje correspondiente al centro de la calibración: `(0.084+3.030)/2 = 1.557 V`.
- ADC esperado: `1.557/5*1023 ≈ 318.6`.
- El firmware reconstruye `318.6*3.3/1023 ≈ 1.028 V`.
- Eso se convierte a aproximadamente `pH 4.48`, no `pH 7`.
- Incluso una entrada de `3.030 V`, que debería representar el extremo pH 14 de esa calibración, se reconstruye cerca de `2.000 V` y produce aproximadamente `pH 9.10`.

**RIESGO — ALTO**

Lectura de pH sistemáticamente incorrecta si esa lógica pasa de potenciómetro a control real.

**RECOMENDACIÓN FUTURA**

Definir referencia ADC real, medir AVCC/AREF cuando corresponda y recalibrar el sistema completo con soluciones patrón.

## H-04 — Pérdida UART puede quedar oculta como telemetría fresca

**HECHO CONFIRMADO**

El gateway conserva en memoria la última trama del Mega y publica a RTDB cada 10 s. El `timestamp` se genera al publicar, no al recibir la trama UART. No hay `lastUartRx`, sequence number ni flag de salud del enlace.

**INFERENCIA**

Si el Mega/UART deja de enviar, el gateway puede seguir publicando valores viejos con timestamp nuevo.

**RIESGO — ALTO**

La app puede interpretar como actuales datos que ya no representan el hardware.

**RECOMENDACIÓN FUTURA**

Publicar edad de muestra, secuencia, estado del enlace y marcar datos stale en origen/app.

## H-05 — Reinicios desincronizan estados sostenidos

**HECHO CONFIRMADO**

Al arrancar, el gateway ejecuta un `setJSON` de todo `/comandos` con `luz=false`, `auxiliar=false`, `bomba=false`, `nutrientes=false`. El comentario dice “si no existe”, pero el código no comprueba existencia.

Para `luz` y `auxiliar`, la primera lectura solo actualiza `lastLuz/lastAux` y no manda estado al Mega.

**INFERENCIA**

- Si el Mega mantiene `LUZ` encendida y solo reinicia el gateway, RTDB pasa a `false`, pero el Mega puede seguir encendido.
- Si el Mega reinicia mientras RTDB/gateway consideran `luz=true`, el Mega arranca con relé apagado y el gateway no necesariamente reenvía `LUZ_ON`, porque no detectó cambio de RTDB.

**RIESGO — ALTO**

Estado cloud/UI y estado físico pueden divergir tras reinicios.

**RECOMENDACIÓN FUTURA**

Definir source-of-truth, reconciliation tras boot y confirmación de estado físico.

## H-06 — Release Android usa firma debug

**HECHO CONFIRMADO**

`buildTypes.release.signingConfig = signingConfigs.getByName("debug")`.

**RIESGO — ALTO**

No es configuración aceptable como identidad final de distribución y complica la transición a Google Sign-In/Play Signing real.

**RECOMENDACIÓN FUTURA**

Crear firma release fuera de Git, registrar certificados correctos y separar configuración de build.

## H-07 — Contrato Firebase Android documentado con package incorrecto

**HECHO CONFIRMADO**

- `namespace`: `cl.huertaviva.huerta_viva_app`.
- `MainActivity`: package `cl.huertaviva.huerta_viva_app`.
- `applicationId`: `com.aselec.hidrosmart`.
- La guía histórica instruye registrar Firebase con `cl.huertaviva.huerta_viva_app`.

El `namespace` y el package Kotlin son coherentes entre sí; no es obligatorio que sean idénticos al `applicationId`.

La configuración Firebase Android debe seleccionar un cliente de `google-services.json` cuyo `package_name` coincida con el package/application ID de la variante, es decir, actualmente `com.aselec.hidrosmart`.

**RIESGO — ALTO**

Seguir la guía histórica puede generar un `google-services.json` incompatible o un OAuth client equivocado.

**RECOMENDACIÓN FUTURA**

Estabilizar primero el identificador final y regenerar configuración Firebase para la variante correcta.

## H-08 — Cámara LAN sin autenticación

**HECHO CONFIRMADO**

ESP32-CAM escucha HTTP en 80 y MJPEG en 81. Lee y descarta el request, sin contraseña, token ni autorización.

**RIESGO — ALTO**

Cualquier cliente con acceso IP a la misma red puede ver el stream.

Además, `atenderStream()` permanece en un `while(cliente.connected())`; mientras un stream está abierto, el `loop()` no vuelve a ejecutar el scheduler de fotografía.

**RECOMENDACIÓN FUTURA**

Definir privacidad de cámara, autenticación y un servidor/loop no bloqueante.

## H-09 — Entrega UART no confirmada

**HECHO CONFIRMADO**

No existe ACK Mega→ESP8266 para comandos. El gateway puede resetear un comando RTDB inmediatamente después de imprimirlo al UART.

**RIESGO — ALTO**

Cloud puede registrar el comando como consumido aunque el controlador no lo haya recibido/aplicado.

**RECOMENDACIÓN FUTURA**

ACK con command ID y resultado del actuador.

---

# 6. HALLAZGOS MEDIOS

## M-01 — `deviceId` y `esp32Id` son contratos paralelos

**HECHO CONFIRMADO**

- `usuarios/{uid}.deviceId` se escribe mediante `saveDeviceId`.
- `usuarios/{uid}/huerta/config.esp32Id` se usa en el modelo `Huerta`.
- `AppUser` también declara `esp32Id`/`esp32Connected`.
- `_toAppUser()` no carga `deviceId`, `esp32Id` ni `esp32Connected` desde Firestore.
- La fuente RTDB real usa `SettingsState.deviceId` local, no el objeto `Huerta`.

**RIESGO — MEDIO**

La vinculación remota puede convertirse en dato write-only y no restaurarse de forma autoritativa en otro teléfono/reinstalación.

## M-02 — Simulador y hardware interpretan comandos de forma diferente

**HECHO CONFIRMADO**

- Simulador: `luz` y `auxiliar` hacen toggle e ignoran `value`.
- Hardware: `luz`/`auxiliar` asignan estado explícito según `value`.
- `SimuladorScreen` manda siempre valor `1` en esos botones.
- Simulador usa 3 s para bomba/nutrientes; Mega usa 5 s.

**RIESGO — MEDIO**

Una UI validada contra simulador puede comportarse diferente al conectar hardware real. En particular, el botón de `LUZ`/`AUX` del simulador puede alternar en mock pero solo encender en hardware.

## M-03 — Restauración de sesión Firebase incompleta

**HECHO CONFIRMADO**

`FirebaseAuthService` implementa `getCurrentUser()` y `authStateChanges()`, pero `authProvider` no se suscribe al stream automáticamente. `SplashScreen` espera 2 s y navega siempre a `/login`.

**RIESGO — MEDIO**

Sesiones persistentes pueden no reflejarse en el estado Riverpod inicial y el usuario vuelve a login.

## M-04 — Timestamp del gateway no representa UTC real

**HECHO CONFIRMADO**

`NTPClient` se construye con offset `-18000`, y `getEpochTime()` de esa librería incorpora el offset. Luego `epochToISO8601()` termina la cadena con `Z`, que semánticamente indica UTC.

**RIESGO — MEDIO**

Timestamp desplazado pero etiquetado como UTC. Además solo se intenta `timeClient.update()` en setup y se ignora el resultado.

## M-05 — Telemetría de fallo DHT indistinguible de dato válido antiguo

**HECHO CONFIRMADO**

Si DHT devuelve NaN, `dhtOK=false`, pero `gTemp/gHum` conservan el último valor válido. La trama UART no incluye `dhtOK`.

**RIESGO — MEDIO**

La app no puede distinguir sensor fallado de temperatura/humedad estable.

## M-06 — Placeholders físicos se publican como números reales

**HECHO CONFIRMADO**

Gateway publica siempre:

- `ec=0.0`;
- `temp_agua=0.0`;
- `nivel_agua=0.0`.

Flutter los parsea como valores numéricos válidos; los defaults solo se usan si falta el campo.

**RIESGO — MEDIO**

La UI puede presentar 0 como medición real y generar estados/alertas engañosos.

## M-07 — Canal UART comparte tráfico de protocolo y logs del gateway

**HECHO CONFIRMADO**

El ESP8266 llama `Serial.swap()` y usa ese mismo `Serial` para leer Mega, mandar comandos y emitir algunos mensajes de error (`Serial.print`). `Serial.swap()` remapea UART0 a GPIO15/GPIO13.

**INFERENCIA**

Los logs explícitos emitidos por `Serial` después del swap viajan por el enlace hacia el Mega, no por un canal de depuración USB independiente.

**RIESGO — MEDIO**

Contaminación del canal de comandos, aunque el Mega ignore actualmente strings desconocidos.

## M-08 — Protocolo UART carece de integridad/versionado

No hay checksum/CRC, sequence ID, versión, longitud declarada ni ACK. `toFloat()/toInt()` pueden convertir contenido malformado a valores 0 sin distinguir error.

## M-09 — Cámara usa identidad temporal débil para fotos

Los nombres de Storage usan `DEVICE_ID + millis()`. Tras cada reboot `millis()` vuelve a cero, por lo que pueden repetirse nombres y sobrescribirse capturas. `ultimaFotoTs` también es `millis()/1000`, no tiempo absoluto.

## M-10 — Funciones presentadas como reales siguen siendo mock

- `ConectarEsp32Screen` simula conexión tras 3 s.
- `ProgramarRiegoScreen` solo guarda estado visual/snackbar; no programa hardware.
- `NutrientesScreen` muestra EC/pH estáticos y “dosificación automática” sin enlazar el actuador real.
- “Reiniciar ESP32” en `MiHuertaScreen` solo espera 2 s y muestra éxito.

---

# 7. HALLAZGOS BAJOS

- `SettingsNotifier.resetAll()` no elimina `usar_hardware` ni `device_id` del storage aunque sí reinicia el estado en memoria; esos valores pueden reaparecer en el próximo arranque.
- `getCosechas(String huertaId)` ignora `huertaId`; actualmente la ruta está asociada solo al usuario.
- `getLecturasSensor`/alertas de Firestore siguen siendo mock incluso con Firebase real.
- El gateway declara `int pos` sin uso en `parsearCSV`; deuda menor.
- `ESP32-CAM` declara `primeraFotoHecha` sin uso.
- Los nombres históricos generan ambigüedad, pero la migración de branding está fuera de alcance.

---

# 8. CONTRATO ANDROID ↔ FIREBASE

| Elemento | Valor confirmado | Evaluación |
|---|---|---|
| namespace | `cl.huertaviva.huerta_viva_app` | Coherente con MainActivity |
| MainActivity package | `cl.huertaviva.huerta_viva_app` | Coherente con namespace |
| applicationId | `com.aselec.hidrosmart` | Identidad Android efectiva actual |
| manifest activity | `.MainActivity` | Resuelve a la clase del namespace actual |
| Google Services plugin | `4.5.0` | Aplicado en app |
| release signing | debug key | No apto para release final |
| Firebase guide legacy | `cl.huertaviva.huerta_viva_app` | Incorrecta para applicationId actual |
| `firebase_options.dart` | No existe | Web/multiplataforma no configurada por FlutterFire |
| flavors | No observados | Solo `debug`, `main`, `profile` bajo `src` |

**SHA**

- Google Sign-In con Firebase en Android requiere registrar SHA-1 del certificado de firma correspondiente.
- El repositorio no contiene el keystore, por lo que el valor SHA-1 concreto no puede determinarse aquí.
- Con la configuración actual, `release` usa la firma debug; cuando exista una firma release/Play App Signing real, habrá que registrar el SHA-1 de producción y descargar un `google-services.json` actualizado con la información OAuth.
- No se encontró una función actual que haga SHA-256 un requisito directo para Google Sign-In básico. SHA-256 puede ser requerido por otros servicios/controles de integridad y debe evaluarse cuando se agreguen.

**HECHO CONFIRMADO**

`google-services.json` no está versionado, por lo que esta auditoría no puede verificar proyecto Firebase, `package_name`, OAuth client IDs ni huellas efectivamente configuradas en consola.

---

# 9. ESQUEMA FIRESTORE

## `usuarios/{uid}`

**Escritores confirmados**

- `FirebaseAuthService._ensureProfile`.
- `saveUserMode`.
- `saveDeviceId`.

**Campos observados**

- `uid`
- `email`
- `displayName`
- `mode`
- `creadoEn`
- `deviceId`
- `deviceVinculadoEn`

**Lectores confirmados**

`FirebaseAuthService._toAppUser()` lee principalmente `displayName` y `mode`.

**Riesgo de consistencia**

`deviceId` se persiste pero no se carga a `AppUser` ni a `SettingsState` desde Firestore.

## `usuarios/{uid}/huerta/config`

**Campos**

- `nombre`
- `capacidadMaxima`
- `esp32Connected`
- `esp32Id`
- `plantas[]` con `plantaId`, `nivel`, `fechaPlantacion`, `activa`
- `actualizadoEn`

**Contrato**

`getHuerta(userId)` lee bajo el `userId` que recibe. `saveHuerta` escribe bajo `FirebaseAuth.currentUser.uid`.

**Riesgo**

Asimetría de identidad y duplicación `deviceId`/`esp32Id`.

## `usuarios/{uid}/cosechas/{id}`

**Campos**

- `plantaId`
- `plantaNombre`
- `emoji`
- `gramos`
- `fecha`
- `nota`

`huertaId` recibido por las funciones no interviene en la ruta actual.

## Datos mock incluso con Firestore activo

- catálogo de plantas;
- lecturas de sensor vía `FirestoreService`;
- alertas y resolución de alertas.

**Autorización esperada**

El cliente presupone un usuario Firebase para varias operaciones, pero las reglas activas no pueden demostrarse porque no están versionadas. La antigua guía contiene un ejemplo user-scoped; no constituye evidencia de reglas desplegadas.

---

# 10. ESQUEMA RTDB

## `/dispositivos/{deviceId}/telemetria`

**Escritor:** ESP8266 cada 10 s.  
**Fuente:** última trama Mega recibida, generada cada 2 s cuando UART funciona.  
**Lector:** Flutter `RTDBService`.

Campos:

- `ph`: number
- `temp_aire`: number
- `humedad`: number
- `ec`: number, actualmente `0.0` placeholder
- `temp_agua`: number, actualmente `0.0` placeholder
- `nivel_agua`: number, actualmente `0.0` placeholder
- `relay_bomba`: bool
- `relay_nutrientes`: bool
- `relay_luz`: bool
- `relay_auxiliar`: bool
- `timestamp`: string ISO-like generada por gateway

## `/dispositivos/{deviceId}/info`

**Escritor:** ESP8266 en setup.

Campos observados:

- `modelo`
- `fw`
- `ip`
- `arranque`

No se confirmó lector Flutter.

## `/dispositivos/{deviceId}/comandos`

Campos:

- `luz`: bool sostenido
- `auxiliar`: bool sostenido
- `bomba`: bool trigger
- `nutrientes`: bool trigger

Gateway sondea cada 3 s.

## `/dispositivos/{deviceId}/camara`

**Escritor:** ESP32-CAM.

Campos:

- `ip`
- `streamUrl`
- `ultimaFotoUrl`
- `ultimaFotoTs`

No se confirmó lector Flutter ni dependencia `firebase_storage` en la app.

---

# 11. OWNERSHIP ACTUAL

**HECHO CONFIRMADO**

El flujo actual permite escribir cualquier string no vacío como `deviceId`, lo convierte a mayúscula, lo guarda en SharedPreferences y llama a `saveDeviceId` en Firestore.

No existe en código versionado:

- challenge físico;
- código de claim de un solo uso;
- secreto por torre;
- verificación del hardware presente;
- mapping autoritativo device→owner usado por RTDB;
- revocación;
- transferencia;
- recuperación.

**INFERENCIA / ESCENARIO DE ATAQUE**

Un usuario autenticado malicioso podría modificar la app o escribir otro `deviceId`. Si las reglas desplegadas permiten acceso a `dispositivos/{deviceId}` por estar autenticado sin verificar ownership, el atacante podría leer telemetría o activar actuadores del ID objetivo.

La auditoría no declara que las reglas reales estén abiertas; declara que el repositorio no permite demostrar la barrera server-side.

---

# 12. IDENTIDAD DE DISPOSITIVO

| Componente | Identidad |
|---|---|
| Flutter default | `HS-001` |
| ESP8266 | `HS-001` compile-time |
| ESP32-CAM | `HS-001` compile-time |
| Firestore user profile | string manual `deviceId` |
| Huerta model | string opcional `esp32Id` |

Con dos torres sin personalización de firmware:

1. ambas publican telemetría al mismo path;
2. ambas reciben el mismo trigger `bomba/nutrientes`;
3. ambas observan los mismos toggles luz/aux;
4. `/info` representa al último escritor;
5. ambas cámaras pisan `/camara`;
6. nombres de fotos basados en mismo ID+uptime pueden colisionar tras reinicios.

---

# 13. AUTENTICACIÓN DEL FIRMWARE

**HECHO CONFIRMADO**

ESP8266 y ESP32-CAM esperan:

- host Firebase;
- `FIREBASE_AUTH` legacy token;
- WiFi SSID/password;
- ID estático.

No se encontró:

- usuario Firebase por dispositivo;
- custom token por unidad;
- certificado por dispositivo;
- renovación/rotación remota;
- secure element;
- secreto individual versionado fuera del source.

**RIESGO**

Si se graba una misma credencial en varias unidades, una extracción de firmware puede ampliar el compromiso a todas las rutas permitidas por esa credencial.

---

# 14. TRAZA DE COMANDOS

## bomba

`RiegoManualScreen` / botón Bomba → `enviarComando('bomba','1')` → RTDB `bomba=true` → gateway `BOMBA_ON\n` → Mega `RELE_BOMBA=LOW` → pulso 5 s → `HIGH`.

Gateway intenta resetear RTDB a `false` inmediatamente tras enviar UART.

Simulador usa 3 s, no 5 s.

## nutrientes

`SimuladorScreen` usa el alias `regar` → `RTDBService` traduce a `nutrientes=true` → gateway `NUTRIENTES_ON\n` → Mega relé nutrientes LOW 5 s → HIGH.

`NutrientesScreen` no ejecuta ese comando; su parte PRO es visual/estática.

El método hardware no acepta `cmd='nutrientes'` directamente; espera `regar` como alias desde UI.

## luz

`enviarComando('luz', value)` → RTDB bool → gateway compara contra `lastLuz` → `LUZ_ON/OFF` → Mega estado sostenido.

`SimuladorScreen` envía siempre `value='1'`; en hardware ese botón solo fuerza ON. En simulador, `luz` hace toggle.

## auxiliar

Mismo patrón que luz. `SimuladorScreen` manda `1`; hardware fuerza ON, simulador hace toggle.

## comandos solo simulador

`ph`, `rellenar`, `modo` son ignorados silenciosamente por `RTDBService` en hardware. El simulador sí implementa esos comandos.

---

# 15. PROTOCOLO UART

## Mega → ESP8266

- baud: 9600
- periodo Mega: 2 s
- terminador: `\n`
- formato: `temp,hum,ph,bomba,nutrientes,luz,aux`
- temp/hum/ph: texto decimal
- relés: `0|1`

Gateway acumula máximo 64 chars. Exige al menos 6 comas, pero no valida rango, checksum ni versión.

## ESP8266 → Mega

Comandos exactos:

- `BOMBA_ON`
- `NUTRIENTES_ON`
- `LUZ_ON`
- `LUZ_OFF`
- `AUX_ON`
- `AUX_OFF`

terminados en `\n`.

Mega acumula máximo 32 chars y solo aplica strings exactos.

## Robustez

**Faltan:**

- frame/version ID;
- CRC/checksum;
- sequence number;
- timestamp de muestra;
- ACK/NACK;
- retransmisión controlada;
- estado de enlace;
- validación numérica/rangos.

Tramas incompletas con menos de 6 comas se descartan. Una trama con estructura de comas válida pero contenido numérico inválido puede transformarse en `0` mediante `toFloat()/toInt()`.

---

# 16. TELEMETRÍA REAL / MOCK / PLACEHOLDER

| Señal | Mega físico actual | Gateway RTDB | Flutter hardware | Simulador |
|---|---|---|---|---|
| pH | **SIMULADO** por potenciómetro A0 | publica valor | muestra como pH | simulado dinámico |
| Temp ambiente | **REAL** DHT22 | publica | real si enlace sano | simulado |
| Humedad | **REAL** DHT22 | publica | real si enlace sano | simulado |
| EC | **NO IMPLEMENTADO** | `0.0` placeholder | puede mostrarse en PRO | simulado dinámico |
| Temp agua | **NO IMPLEMENTADO** | `0.0` placeholder | puede mostrarse | simulado dinámico |
| Nivel agua | **NO IMPLEMENTADO** | `0.0` placeholder | puede mostrarse | simulado dinámico |
| Bomba | estado real Mega | publica bool | lee estado | simulado |
| Nutrientes | estado real Mega | publica bool | lee estado | simulado |
| Luz | estado real Mega | publica bool | lee estado | simulado |
| Auxiliar | estado real Mega | publica bool | lee estado | simulado |

**Nota:** cuando falla DHT, Mega conserva el último valor y no transmite un indicador de fallo.

---

# 17. ANÁLISIS ADC / pH

**HECHO CONFIRMADO**

- ADC: `analogRead(A0)` de 10 bits.
- filtro: promedio móvil de 10 muestras.
- potenciómetro recomendado en comentario a 3.3 V.
- no se configura `analogReference`.
- fórmula raw→V usa 3.3 V.

**CONCLUSIÓN TÉCNICA**

La fórmula raw→voltaje no es coherente con el ADC por defecto de un Mega estándar alimentado a 5 V. La tensión de alimentación del potenciómetro y la tensión de referencia ADC son conceptos distintos.

El promedio móvil es correcto como suavizado básico, pero no corrige el error de escala.

**RIESGO**

El valor de pH calculado no representa la calibración declarada. No debe usarse para dosificación automática real.

---

# 18. FAIL-SAFE

## ESP8266 pierde WiFi

- Mega sigue funcionando localmente.
- bomba/nutrientes ya activos se apagan por timer local.
- luz/aux permanecen en su último estado.
- nuevos comandos cloud no llegan.

## Firebase falla

- gateway omite acciones si las llamadas fallan, pero no existe una máquina de estados formal de degradación.
- un trigger momentáneo puede ser reenviado si no se consigue resetear.

## UART se desconecta

- Mega conserva control local y timers.
- gateway puede publicar cache viejo con timestamp nuevo.
- gateway no sabe si un comando fue aplicado.

## Mega reinicia

En `setup`, todos los relés se llevan a HIGH (apagado). Esto es un fail-safe favorable para el arranque. Sin embargo, gateway/RTDB pueden conservar un estado lógico distinto para luz/aux sin reconciliarlo.

## ESP8266 reinicia

Sobrescribe `/comandos` con todo `false`. Puede perder comandos pendientes y desincronizar estado sostenido del Mega.

## App repite comando

No hay command ID ni deduplicación end-to-end. Los triggers momentáneos se representan únicamente como bool.

## RTDB mantiene `true`

Puede provocar reenvíos cada 3 s; en Mega el nuevo comando vuelve a extender el deadline 5 s.

## Falla de alimentación

El comportamiento una vez ejecutado `setup` es relés apagados. El estado eléctrico transitorio previo a `setup` depende de la placa/módulo/cableado y no puede certificarse desde este repositorio.

## Overflow de `millis()`

Los checks periódicos basados en resta unsigned son generalmente rollover-safe para estos intervalos cortos. El patrón del Mega para deadline usa resta y cast signed y, con ventanas de 5 s, no aparece como riesgo prioritario. Debe cubrirse con test cuando se formalice firmware.

---

# 19. ESP32-CAM

**WiFi:** credenciales compile-time placeholder.  
**HTTP:** página en 80.  
**MJPEG:** stream en 81.  
**Auth LAN:** ninguna.  
**RTDB:** `/dispositivos/HS-001/camara`.  
**Storage:** captura cada 6 h, con primera captura aproximadamente a 30 s.  
**DEVICE_ID:** hardcodeado.  
**Error cámara:** reinicia el ESP si `esp_camera_init` falla.

## Privacidad

Cualquier equipo con acceso a la IP local puede solicitar el stream. No existe control de usuario.

## Scheduler

El streaming usa un loop bloqueante mientras el cliente permanezca conectado. Una visualización prolongada puede impedir que el loop principal ejecute la captura periódica.

## Storage URL

El firmware construye manualmente una URL `firebasestorage.googleapis.com/...?...alt=media` y la llama “pública”. El repositorio no contiene Storage Rules ni token de descarga, por lo que no puede confirmarse que esa URL sea realmente legible públicamente. La seguridad/funcionamiento depende de configuración externa.

## Timestamp/ficheros

`ultimaFotoTs=millis()/1000` es uptime, no epoch. Los nombres también usan `millis()`, por lo que reinicios pueden reutilizar nombres y afectar el timelapse.

---

# 20. PROVISIONING ACTUAL

**HECHO CONFIRMADO**

`ConectarEsp32Screen`:

1. muestra “Conecta tu huerta al WiFi”;
2. afirma que detectará ESP32 por Bluetooth;
3. al pulsar buscar, espera 3 s;
4. cambia `_connected=true` sin I/O de red/radio;
5. permite omitir el paso.

`pubspec.yaml` no declara biblioteca BLE.

El gateway activo es ESP8266 y no contiene implementación de provisioning WiFi.

La vinculación real disponible está en una pantalla de desarrollo: se escribe manualmente `deviceId` y se guarda.

**NO EXISTE ACTUALMENTE**

- BLE discovery;
- BLE provisioning;
- SoftAP provisioning;
- SmartConfig;
- QR claim verificado;
- prueba de posesión;
- handshake con gateway;
- confirmación física.

---

# 21. DEV / PROD

**HECHO CONFIRMADO**

No se encontraron:

- product flavors;
- Firebase projects por flavor;
- `firebase_options.dart`;
- compile-time env abstraction;
- configuración diferenciada staging/prod;
- mecanismo explícito para prohibir mocks en release.

Los firmwares requieren editar placeholders source para WiFi/Firebase.

**RIESGO**

Desarrollo, simulación y producción están separados por flags/estado runtime, no por límites de build/deployment fuertes.

---

# 22. THREAT MODEL

## Usuario legítimo

Riesgo principal: errores de estado pueden accionar algo distinto a lo mostrado o presentar telemetría stale/placeholder como real.

## Usuario autenticado malicioso

Camino potencial: modificar `deviceId` → acceder a otro nodo RTDB → leer/mandar comandos, **si** las reglas desplegadas no verifican ownership.

## Atacante en LAN

Camino confirmado: descubrir IP del ESP32-CAM → HTTP 80/81 → ver stream sin autenticación.

## Persona que conoce un deviceId

El ID no constituye secreto. Con un cliente capaz de escribir RTDB y reglas insuficientes, podría apuntar al dispositivo conocido.

## Dispositivo comprometido

Si varias unidades comparten legacy token, extraer una credencial podría permitir impersonar/escribir otras rutas dentro de su alcance.

## Aplicación modificada

Las restricciones UI no son security boundaries. Puede llamar directamente a RTDB, escoger IDs, enviar comandos o ignorar modos BASIC/ECO/PRO. Solo reglas server-side y validación del dispositivo pueden imponer seguridad.

## Activos

- bomba y relé de nutrientes;
- luz/auxiliar;
- cultivo/solución nutritiva;
- telemetría;
- fotografías;
- cuenta Firebase;
- identidad/ownership del dispositivo;
- credenciales firmware.

## Caminos prioritarios de ataque/falla

1. ID compartido → control cruzado accidental.
2. RTDB ownership insuficiente → control cruzado intencional.
3. replay/retry de bool `true` → sobre-actuación.
4. token compartido extraído → acceso cloud ampliado.
5. stream LAN sin auth → pérdida de privacidad.
6. telemetría stale → decisiones automáticas/humanas incorrectas.
7. app modificada → bypass de cualquier limitación solo visual.

---

# 23. TOP 10 CORRECCIONES RECOMENDADAS EN ORDEN

1. **Definir identidad única y provisioning de cada torre**, incluyendo claim físico y ciclo de transferencia/revocación.
2. **Versionar y testear Firebase Security Rules** para Firestore, RTDB y Storage, con ownership device↔UID como barrera server-side.
3. **Rediseñar comandos de actuadores** con IDs, TTL, ACK end-to-end, idempotencia, estados y límites locales de duty-cycle.
4. **Eliminar el esquema de legacy token compartido** y adoptar autenticación por dispositivo; planificar migración desde librerías Firebase Mobizt deprecadas.
5. **Separar dev/staging/prod**; una build de producción nunca debe caer a MockAuth/MockFirestore.
6. **Corregir referencia ADC y recalibrar pH** antes de conectar una sonda o automatizar dosificación.
7. **Implementar health/freshness y reconciliación de estados** Mega↔gateway↔RTDB, especialmente tras reset/pérdida UART.
8. **Estabilizar Android↔Firebase**: applicationId final, google-services correcto, SHA-1 debug/release/Play y firma release real.
9. **Asegurar ESP32-CAM**: autenticación/privacidad LAN, Storage Rules, timestamps absolutos, nombres únicos y loop no bloqueante.
10. **Versionar y endurecer UART**: frame version, CRC, sequence, validación, ACK y canal de debug separado.

---

# 24. COMMITS CREADOS

Un único commit documental debe contener esta auditoría. El SHA se registra en la entrega del agente una vez creado el archivo.

No se deben crear commits de código ni mergear esta rama.

---

# 25. DIFF FINAL

Criterio de aceptación:

`main...audit/system-contracts` debe contener únicamente:

- `docs/audits/system-contracts-audit.md`

Cualquier otro cambio invalida el alcance de esta fase.

---

## Referencias técnicas externas usadas para validar supuestos

Se contrastaron únicamente fuentes primarias/oficiales para los puntos que dependen de comportamiento de plataforma:

- Firebase: configuración Android, matching de `google-services.json`, Google Sign-In y huella SHA-1.
- Microchip: referencia ADC/AVCC del AVR.
- Arduino: características de Mega 2560 y fuente oficial de `NTPClient`.
- ESP8266 Arduino Core: comportamiento de `Serial.swap()`.
- Upstream Mobizt: estado deprecado/EOL de las bibliotecas Firebase antiguas y recomendación de `FirebaseClient`.

No se realizaron pruebas contra Firebase real, dispositivos externos ni sistemas de terceros.