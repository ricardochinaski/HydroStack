# Command protocol v2

Este documento define el contrato de comandos introducido en `feat/command-protocol-foundation`.

## Objetivo

Evitar que un booleano momentáneo en RTDB pueda convertirse en múltiples activaciones físicas por reinicios, relecturas, fallos parciales o reintentos del gateway.

El principio es:

```text
usuario autorizado
    ↓
comando inmutable + commandId + TTL
    ↓
puntero del actuador
    ↓
ESP8266 valida vigencia
    ↓
CMD|commandId|type|value
    ↓
Mega valida + aplica como máximo una vez
    ↓
ACK|commandId|status|code
    ↓
ESP8266 persiste ACK
    ↓
RTDB commandAcks
```

## RTDB

### Registro inmutable

Cada solicitud se crea bajo:

```text
/dispositivos/{deviceId}/comandos/{actuator}/{commandId}
```

Campos:

```text
commandId:   String
value:       bool
issuedAt:    timestamp RTDB en milisegundos generado con ServerValue.timestamp
ttlMs:       number entre 1000 y 15000
requestedBy: Firebase Auth UID
```

Los actuadores permitidos son `luz`, `auxiliar`, `bomba` y `nutrientes`.

Para `bomba` y `nutrientes`, `value` solo puede ser `true`. La duración física no llega desde la nube: el Mega conserva `PULSO_MS = 5000` como límite local.

El registro no puede editarse ni borrarse desde cliente después de crearse.

### Puntero

Después de crear correctamente el registro, la app actualiza:

```text
/dispositivos/{deviceId}/commandPointers/{actuator} = commandId
```

El puntero solo puede apuntar a un comando existente del mismo actuador cuyo `requestedBy` coincida con el usuario autenticado.

Un fallo al mover el puntero puede dejar un comando huérfano, pero ese comando no se ejecuta porque el gateway solo consume el ID referenciado por `commandPointers`.

### Serialización por actuador

El ESP8266 mantiene como máximo un comando en vuelo por actuador.

Mientras `pendingId` esté ocupado:

- un nuevo `commandPointer` del mismo actuador no inicia otra ejecución;
- el comando anterior no se marca como `SUPERSEDED`;
- el actuador continúa bloqueado aunque el Mega ya haya respondido, hasta que el ACK terminal quede realmente persistido en Firebase;
- una vez persistido el estado terminal, el siguiente poll puede evaluar el pointer más reciente.

Esta política privilegia no duplicar una actuación física por sobre procesar rápidamente dos órdenes consecutivas.

### ACK

El gateway publica:

```text
/dispositivos/{deviceId}/commandAcks/{actuator}/{commandId}
```

con:

```text
commandId
status
code
at
```

Estados definidos:

- `APPLIED`: el Mega confirmó aplicación.
- `DUPLICATE`: el `commandId` ya había sido aplicado y no se volvió a actuar.
- `REJECTED`: existe evidencia de que el comando fue rechazado antes o por el Mega.
- `EXPIRED`: el TTL venció antes del primer envío al Mega.
- `UNKNOWN`: el gateway ya pudo haber enviado el comando, pero no recibió evidencia suficiente para afirmar si se aplicó.

Códigos observables incluyen:

- `OK`
- `ALREADY_APPLIED`
- `BOOT_GUARD`
- `ALREADY_ACTIVE`
- `COOLDOWN`
- `INVALID_ID`
- `INVALID_VALUE`
- `UNKNOWN_COMMAND`
- `ID_MISMATCH`
- `INVALID_ENVELOPE`
- `TTL_EXPIRED`
- `TTL_EXPIRED_WAITING_ACK`
- `MEGA_NO_ACK`

`SUPERSEDED` ya no forma parte del contrato: cambiar el pointer no autoriza a descartar una orden que podría haber sido aplicada físicamente.

Los clientes no pueden escribir `commandAcks`.

## Persistencia del ACK

Recibir un ACK por UART y persistirlo en Firebase son eventos distintos.

Cuando llega un ACK del Mega:

1. el gateway detiene los reintentos UART de ese `commandId`;
2. conserva `pendingId`, `status` y `code` en memoria;
3. intenta escribir `commandAcks/{actuator}/{commandId}`;
4. si `Firebase.setJSON()` falla, mantiene el actuador bloqueado y reintenta la persistencia;
5. solo después de una escritura exitosa actualiza `lastSeenId` y libera el slot del actuador.

Por tanto, una caída temporal de Firebase no hace que una orden posterior se adelante a un resultado terminal todavía no registrado.

## Seguridad temporal

Las reglas RTDB validan que `issuedAt` esté dentro de una ventana de cinco segundos respecto de `now`, el reloj del servidor RTDB. La app utiliza `ServerValue.timestamp`.

El gateway usa UTC y antes del primer envío rechaza cualquier comando cuyo:

```text
now > issuedAt + ttlMs
```

Si NTP todavía no está sincronizado, el gateway no ejecuta ni marca definitivamente la orden; vuelve a evaluarla en un poll posterior.

Si el comando ya fue enviado y luego vence esperando ACK, el gateway publica `UNKNOWN / TTL_EXPIRED_WAITING_ACK`, no `EXPIRED`, porque el Mega podría haber actuado antes de perderse la confirmación.

## commandId

La app obtiene el ID desde una push key de RTDB.

Las reglas y el gateway restringen el ID a:

```text
^[A-Za-z0-9_-]{8,23}$
```

Esto evita introducir el delimitador `|` o caracteres inseguros en el framing UART.

## UART v2

Gateway → Mega:

```text
CMD|<commandId>|<type>|<0|1>\n
```

Tipos:

```text
LIGHT_SET
AUX_SET
PUMP_PULSE
NUTRIENTS_PULSE
```

Mega → gateway:

```text
ACK|<commandId>|<status>|<code>\n
```

La telemetría Mega → gateway conserva el CSV anterior para no mezclar esta fase con una migración general del protocolo de telemetría.

## Reintentos del gateway

Por actuador:

- primer envío inmediato;
- reintento cada `1500 ms`;
- máximo `3` envíos UART;
- todos los reintentos reutilizan exactamente el mismo `commandId`;
- no se vuelve a enviar UART después de recibir un ACK del Mega;
- si tras los intentos no existe ACK, se registra `UNKNOWN / MEGA_NO_ACK`;
- el resultado terminal se reintenta contra Firebase hasta persistirse.

`MEGA_NO_ACK` significa resultado físico desconocido, no rechazo demostrado.

## Idempotencia del Mega

Para `bomba` y `nutrientes`, el último `commandId` aplicado se persiste en EEPROM antes de energizar el relé.

Si vuelve a llegar el mismo ID, el Mega responde:

```text
DUPLICATE / ALREADY_APPLIED
```

sin volver a activar el relé.

Además:

- pulso físico: `5000 ms` local;
- cooldown desde inicio de pulso: `10000 ms`;
- guard de boot para nuevos pulsos: `10000 ms`;
- relés parten apagados en `setup()`.

Luz y auxiliar son operaciones de estado; reenviar el mismo valor es físicamente idempotente. Durante una misma sesión el Mega también recuerda su último `commandId` para responder `DUPLICATE`.

## Reinicios

### Reinicio del gateway

El estado `pendingId` está en RAM y se pierde. El pointer y el registro inmutable permanecen en RTDB. Si el TTL sigue vigente, el gateway puede reenviar el mismo `commandId`.

Para bomba/nutrientes, EEPROM en el Mega evita un segundo pulso si el comando ya había sido aplicado. Para luz/auxiliar, volver a establecer el mismo estado es idempotente.

Persiste una ventana de ambigüedad de observabilidad hasta que el gateway reconstruye y obtiene un ACK; esta fase no introduce almacenamiento durable del estado pendiente en el ESP8266.

### Reinicio del Mega

Los relés parten apagados. Para bomba y nutrientes, el último `commandId` aplicado permanece en EEPROM, por lo que un reintento del mismo ID se clasifica como duplicado sin otro pulso.

## Compatibilidad legacy

El parser legacy del Mega se conserva como código de adaptación, pero:

```text
ENABLE_LEGACY_UART_COMMANDS = 0
```

por defecto.

El gateway v4.2 ya no escribe ni consume los booleanos legacy de comandos.

## Fuera de alcance

Esta fase no resuelve:

- autenticación IoT del ESP8266;
- sustitución del legacy Firebase token;
- identidad única real del firmware;
- provisioning físico;
- ADC/pH;
- cámara;
- branding;
- almacenamiento durable del pending state en el gateway;
- retención/limpieza automática de registros históricos de comandos y ACKs.

La autenticación IoT debe ser la siguiente barrera de seguridad antes de considerar este protocolo listo para producción.
