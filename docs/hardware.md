# Hardware confirmado

La fuente principal de esta documentación es el firmware activo. Los prototipos HTML y listas de compra se consideran históricos y están en `docs/legacy/`; no se usan para afirmar que un componente esté instalado actualmente.

## Arduino Mega 2560

Funciona como controlador local de sensores, pantalla y actuadores.

| Elemento | Función | Pines confirmados |
| --- | --- | --- |
| DHT22 | Temperatura y humedad ambiente | Digital 2 |
| Potenciómetro | Simulación de entrada de pH con promedio móvil | A0; alimentado a 3.3 V según la calibración actual |
| TFT ILI9341 | Interfaz local 320 x 240 | SPI del Mega: MOSI 51, MISO 50, SCK 52; CS 10, DC 9, RST 8 |
| Relé bomba | Circulación/riego, pulso de 5 s | 22 |
| Relé nutrientes | Dosificación, pulso de 5 s | 23 |
| Relé luz | Iluminación, estado sostenido | 24 |
| Relé auxiliar | Reserva/uso futuro, estado sostenido | 25 |
| UART `Serial1` | Comunicación con ESP8266 a 9600 baud | TX1 18, RX1 19 |

Los relés están implementados como activos en LOW. El valor de pH no procede aún de una sonda confirmada: el firmware declara explícitamente un potenciómetro como simulador.

## Gateway ESP8266

La placa confirmada es un ESP8266 NodeMCU. En la versión activa actúa exclusivamente como puente WiFi/Firebase y UART.

- UART de hardware a 9600 baud, reubicada con `Serial.swap()` a GPIO15 (TX) y GPIO13 (RX).
- La línea Mega TX de 5 V hacia ESP8266 RX requiere el divisor de tensión documentado en el firmware: 10 kΩ y 22 kΩ.
- Publica telemetría e información del dispositivo en RTDB.
- Lee comandos RTDB y los reenvía al Mega.
- Usa `Firebase ESP8266 Client`, `NTPClient` y `WiFiUDP`.

El firmware exige tierra común entre Mega y ESP8266.

## ESP32-CAM

El nodo de cámara usa el pinout AI-Thinker declarado en el firmware:

| Señal | GPIO |
| --- | --- |
| PWDN | 32 |
| RESET | -1 |
| XCLK | 0 |
| SIOD / SIOC | 26 / 27 |
| Y9..Y2 | 35, 34, 39, 36, 21, 19, 18, 5 |
| VSYNC / HREF / PCLK | 25 / 23 / 22 |
| Flash integrado | 4 |

La cámara se configura en JPEG y usa PSRAM cuando está disponible. Tiene WiFi propio, streaming local y una integración prevista con RTDB y Storage. No usa UART con los otros nodos.

## Protocolo UART activo

Mega a ESP8266, cada dos segundos:

```text
temp,hum,ph,bomba,nutrientes,luz,aux\n
```

ESP8266 a Mega:

```text
BOMBA_ON
NUTRIENTES_ON
LUZ_ON
LUZ_OFF
AUX_ON
AUX_OFF
```

## Simulación y placeholders

- El proyecto Wokwi usa un ESP32 DevKit, potenciómetros en GPIO34/GPIO35 y salidas en GPIO25/GPIO26/GPIO27. Es una simulación separada, no el cableado del conjunto Mega + ESP8266 activo.
- EC, temperatura de agua y nivel de agua se publican como `0.0` placeholders desde el gateway activo porque esos sensores no están presentes en el firmware Mega actual.
- La entrada pH del Mega es un potenciómetro simulado.
- El relé auxiliar está reservado para uso futuro.

Los diagramas y BOM históricos se conservan bajo `docs/legacy/` y no se presentan como diseño final.
