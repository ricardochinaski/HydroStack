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
Mega valida + aplica una sola vez
    ↓
ACK|commandId|status|code
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
issuedAt:    timestamp RTDB en milisegundos
            generado con ServerValue.timestamp
ttlMs:       number entre 1000 y 15000
requestedBy: Firebase Auth UID
```

Los actuadores permitidos son:

- `luz`
- `auxiliar`
- `bomba`
- `nutrientes`

Para `bomba` y `nutrientes`, `value` solo puede ser `true`. La duración física no llega desde la nube: el Mega conserva `PULSO_MS = 5000` como límite local.

El registro no puede editarse ni borrarse desde cliente después de crearse.

### Puntero

Después de crear correctamente el registro, la app actualiza:

```text
/dispositivos/{deviceId}/commandPointers/{actuator} = commandId
```

El puntero solo puede apuntar a un comando existente del mismo actuador cuyo `requestedBy` coincida con el usuario autenticado.

Un fallo al mover el puntero puede dejar un comando huérfano, pero ese comando no se ejecuta porque el gateway solo consume el ID referenciado por `commandPointers`.

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
- `DUPLICATE`: el commandId ya había sido aplicado y no se volvió a actuar.
- `REJECTED`: el comando no fue aplicado.
- `EXPIRED`: el TTL venció antes de poder completarse.

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
- `SUPERSEDED`
- `MEGA_NO_ACK`

Los clientes no pueden escribir `commandAcks`.

## Seguridad temporal

Las reglas RTDB validan que `issuedAt` esté dentro de una ventana de cinco segundos respecto de `now`, el reloj del servidor RTDB. La app utiliza `ServerValue.timestamp`.

El gateway usa UTC y rechaza cualquier comando cuyo:

```text
now > issuedAt + ttlMs
```

Si NTP todavía no está sincronizado, el gateway no marca el comando como consumido; vuelve a intentarlo en un poll posterior en vez de convertir una dependencia temporal en un rechazo definitivo.

## commandId

La app obtiene el ID desde una push key de RTDB.

Las reglas restringen el ID a:

```text
^[A-Za-z0-9_-]{8,23}$
```

Esto evita introducir el delimitador `|` utilizado por UART.

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

El ESP8266 mantiene como máximo una orden pendiente por actuador.

- primer envío inmediato;
- reintento cada `1500 ms`;
- máximo `3` envíos UART;
- nunca se reenvía después del TTL;
- si no llega ACK, publica `REJECTED / MEGA_NO_ACK`.

Los reintentos reutilizan exactamente el mismo `commandId`.

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

Luz y auxiliar son operaciones de estado; reenviar el mismo valor es físicamente idempotente. Durante una misma sesión el Mega también recuerda su último commandId para responder `DUPLICATE`.

## Compatibilidad legacy

El parser legacy del Mega se conserva como código de adaptación, pero:

```text
ENABLE_LEGACY_UART_COMMANDS = 0
```

por defecto.

El gateway v4.1 ya no escribe ni consume los booleanos legacy de comandos.

## Fuera de alcance

Esta fase no resuelve:

- autenticación IoT del ESP8266;
- sustitución del legacy Firebase token;
- identidad única real del firmware;
- provisioning físico;
- ADC/pH;
- cámara;
- branding;
- retención/limpieza automática de registros históricos de comandos y ACKs.

La autenticación IoT debe ser la siguiente barrera de seguridad antes de considerar este protocolo listo para producción.
