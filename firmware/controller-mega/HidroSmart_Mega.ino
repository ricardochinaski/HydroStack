/**
 * HidroSmart — Arduino Mega 2560 (nodo local)
 * Concentra sensores, pantalla TFT y actuadores (relés).
 * Se comunica con el ESP8266 (gateway WiFi/Firebase) por UART (Serial1).
 *
 * Sensores:
 *  - DHT22            → temperatura y humedad ambiente
 *  - Potenciómetro A0  → simulador de pH (filtro promedio móvil de 10 muestras)
 *
 * Actuadores (relés, activos en LOW):
 *  - BOMBA        → circulación/riego general.       Pulso de 5 s (momentáneo)
 *  - NUTRIENTES   → dosificación de solución nutritiva. Pulso de 5 s (momentáneo)
 *  - LUZ          → iluminación LED.                  Toggle (estado sostenido)
 *  - AUXILIAR     → relé de reserva / uso futuro.      Toggle (estado sostenido)
 *
 * Protocolo UART (Serial1, 9600 baud, hacia/desde el ESP8266):
 *  Mega → ESP8266 (cada 2 s):
 *    "temp,hum,ph,bomba,nutrientes,luz,aux\n"   (temp/hum/ph como floats, relés 0|1)
 *  ESP8266 → Mega (bajo demanda, según comandos de Firebase):
 *    "BOMBA_ON\n" | "NUTRIENTES_ON\n" | "LUZ_ON\n" | "LUZ_OFF\n" | "AUX_ON\n" | "AUX_OFF\n"
 *
 * ⚠️ IMPORTANTE — DOMINIO DE VOLTAJE DEL POTENCIÓMETRO:
 * Las constantes V_MIN/V_MAX de calibración fueron medidas con el potenciómetro
 * alimentado a 3.3V (cuando vivía en el ESP8266). Para que seas puedas REUTILIZAR
 * esas mismas constantes sin recalibrar, alimenta el potenciómetro desde el pin
 * 3.3V del Mega (no desde 5V) — el wiper sigue leyéndose en A0 sin problema aunque
 * el Mega tenga ADC de referencia 5V, solo usa una porción menor de su rango.
 * Si prefieres alimentarlo a 5V, deberás recalibrar V_MIN/V_MAX (ver comentario
 * junto a esas constantes más abajo).
 *
 * Librerías (Library Manager):
 *  · Adafruit ILI9341        · Adafruit GFX Library
 *  · DHT sensor library      · Adafruit Unified Sensor
 */

#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <Fonts/FreeSansBold18pt7b.h>
#include <DHT.h>

// ── PINES ────────────────────────────────────────────────────────
#define PIN_DHT     2
#define PIN_PH      A0

// TFT: usa el bus SPI de hardware del Mega (MOSI=51, MISO=50, SCK=52).
// Solo CS/DC/RST son configurables:
#define TFT_CS      10
#define TFT_DC      9
#define TFT_RST     8

// Relés (módulo típico activo en LOW: LOW = encendido, HIGH = apagado)
#define RELE_BOMBA       22
#define RELE_NUTRIENTES  23
#define RELE_LUZ         24
#define RELE_AUX         25

// ── OBJETOS ──────────────────────────────────────────────────────
Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);
DHT              dht(PIN_DHT, DHT22);

// ── PALETA MODERNA (RGB565) ───────────────────────────────────────
#define C_BG       0x0882   // fondo casi negro azulado
#define C_CARD     0x10C4   // superficie de tarjeta
#define C_BORDE    0x31A7   // borde sutil
#define C_TRACK    0x2125   // pista de barras
#define C_VERDE    0x3DCA
#define C_AMBAR    0xD4C4
#define C_ROJO     0xFA89
#define C_AZUL     0x5D3F
#define C_NARANJA  0xFCE8
#define C_TEAL     0x2EB7
#define C_TEXTO    0xE77E
#define C_GRIS     0x8CB3

// ── LAYOUT (320×240 landscape) ────────────────────────────────────
// Header        y=0..26   (marca)
// Tarjeta pH    y=28..120 (héroe: valor + barra degradada + chip estado)
// Tarjetas T/H  y=124..186 (temperatura + humedad, lado a lado)
// Tira de relés y=190..236 (4 chips: bomba, nutrientes, luz, auxiliar)

#define PHC_Y   28
#define PHC_H   92
#define BAR_X   24
#define BAR_Y   94
#define BAR_W   272
#define BAR_H   8
#define BAR_CY  (BAR_Y + BAR_H / 2)

#define CB_Y    124
#define CB_H    62
#define CT_X    8
#define CH_X    164
#define CB_W    148

#define RELAY_Y 190
#define RELAY_H 46
#define REL_W   74   // ancho de cada chip de relé

const float PH_VIS_MIN = 4.0f;
const float PH_VIS_MAX = 10.0f;

// ── FILTRO PROMEDIO MÓVIL pH ──────────────────────────────────────
static const uint8_t VENTANA = 10;
int     bufPH[VENTANA];
uint8_t idxPH   = 0;
long    sumaBuf = 0;

// ── CALIBRACIÓN POTENCIÓMETRO → pH ───────────────────────────────
// Válida SOLO si el potenciómetro está alimentado a 3.3V (ver nota arriba).
// Si lo alimentas a 5V, recalibra así: V_MIN = 0.0025*1023*3.3/5 (ajusta con
// una lectura real en los extremos del potenciómetro y despeja).
const float V_MIN = 0.084f;
const float V_MAX = 3.030f;

// ── TELEMETRÍA / ESTADO ───────────────────────────────────────────
float gPH   = 7.0f;
float gTemp = 0.0f;
float gHum  = 0.0f;
bool  dhtOK = false;

bool gBomba      = false;   // pulso momentáneo
bool gNutrientes = false;   // pulso momentáneo
bool gLuz        = false;   // toggle sostenido
bool gAux        = false;   // toggle sostenido

unsigned long tFinBomba      = 0;   // millis() en que se apaga el pulso
unsigned long tFinNutrientes = 0;

// Estado previo (actualización diferencial, anti-flicker)
float prevPH = -999.f, prevTemp = -999.f, prevHum = -999.f;
bool  prevDhtOK = true;
int   prevEstado = -1;
int   prevKnobX  = -1;
bool  prevBomba = false, prevNut = false, prevLuz = false, prevAux = false;

// ── TIMING ────────────────────────────────────────────────────────
const unsigned long T_SENSOR   = 2000UL;
const unsigned long PULSO_MS   = 5000UL;  // duración de bomba/nutrientes
unsigned long tSensor = 0;

// ── BUFFER UART ───────────────────────────────────────────────────
String uartBuf = "";

// =================================================================
// PROTOTIPOS
void leerSensores();
void initBufferPH();
void actualizarDisplay();
void enviarTelemetria();
void escucharComandos();
void aplicarComando(const String& cmd);
void actualizarPulsos();

void dibujarUIEstatica();
void dibujarValorPH();
void dibujarChipEstado(int estado);
void moverKnobPH();
void dibujarGradiente(int xa, int xb);
void maskEsquinasBarra();
void dibujarValorTemp();
void dibujarValorHum();
void dibujarTiraReles();
void dibujarChipRele(int x, const char* label, bool activo);
void iconoTermometro(int x, int y);
void iconoGota(int x, int y);

int      estadoPH(float ph);
uint16_t colorEstado(int estado);
uint16_t rgb565(uint8_t r, uint8_t g, uint8_t b);
uint16_t colorSuavePH(float ph);

// =================================================================
void setup() {
  Serial.begin(9600);     // Monitor de depuración USB
  Serial1.begin(9600);    // UART hacia el ESP8266 (TX1=18, RX1=19)

  pinMode(RELE_BOMBA, OUTPUT);      digitalWrite(RELE_BOMBA, HIGH);      // apagado
  pinMode(RELE_NUTRIENTES, OUTPUT); digitalWrite(RELE_NUTRIENTES, HIGH); // apagado
  pinMode(RELE_LUZ, OUTPUT);        digitalWrite(RELE_LUZ, HIGH);        // apagado
  pinMode(RELE_AUX, OUTPUT);        digitalWrite(RELE_AUX, HIGH);        // apagado

  tft.begin();
  tft.setRotation(1);   // landscape 320×240
  tft.setTextWrap(false);
  tft.fillScreen(C_BG);

  // Splash breve
  tft.fillTriangle(160, 46, 140, 88, 180, 88, C_TEAL);
  tft.fillCircle(160, 92, 20, C_TEAL);
  tft.fillCircle(152, 86, 4, C_TEXTO);
  tft.setFont(&FreeSansBold18pt7b);
  tft.setTextSize(1);
  int16_t bx, by; uint16_t bw, bh;
  tft.getTextBounds("HidroSmart", 0, 0, &bx, &by, &bw, &bh);
  tft.setTextColor(C_TEXTO);
  tft.setCursor((320 - bw) / 2 - bx, 150);
  tft.print("HidroSmart");
  tft.setFont();
  tft.setTextSize(1);
  tft.setTextColor(C_GRIS);
  tft.setCursor(78, 164);
  tft.print("Nodo local: sensores + rele\x0Fs");
  delay(1200);

  dht.begin();
  initBufferPH();
  leerSensores();

  tft.fillScreen(C_BG);
  dibujarUIEstatica();
  actualizarDisplay();
  dibujarTiraReles();
}

// =================================================================
void loop() {
  unsigned long t = millis();

  if (t - tSensor >= T_SENSOR) {
    tSensor = t;
    leerSensores();
    actualizarDisplay();
    enviarTelemetria();
  }

  escucharComandos();
  actualizarPulsos();
}

// =================================================================
// Rellena el buffer con la primera lectura real (sin sesgo inicial)
void initBufferPH() {
  int primera = analogRead(PIN_PH);
  sumaBuf = (long)primera * VENTANA;
  for (uint8_t i = 0; i < VENTANA; i++) bufPH[i] = primera;
}

// =================================================================
void leerSensores() {
  int cruda = analogRead(PIN_PH);
  sumaBuf = sumaBuf - bufPH[idxPH] + cruda;
  bufPH[idxPH] = cruda;
  idxPH = (idxPH + 1) % VENTANA;

  int promedio = (int)(sumaBuf / VENTANA);
  float voltaje = (float)promedio * 3.3f / 1023.0f;
  gPH = ((voltaje - V_MIN) * 14.0f) / (V_MAX - V_MIN);
  gPH = constrain(gPH, 0.0f, 14.0f);

  float t = dht.readTemperature();
  float h = dht.readHumidity();
  dhtOK = !isnan(t) && !isnan(h);
  if (dhtOK) { gTemp = t; gHum = h; }
}

// =================================================================
// Apaga los relés de pulso (bomba/nutrientes) cuando expira su tiempo.
void actualizarPulsos() {
  unsigned long t = millis();
  if (gBomba && (long)(t - tFinBomba) >= 0) {
    gBomba = false;
    digitalWrite(RELE_BOMBA, HIGH);
  }
  if (gNutrientes && (long)(t - tFinNutrientes) >= 0) {
    gNutrientes = false;
    digitalWrite(RELE_NUTRIENTES, HIGH);
  }
  if (gBomba != prevBomba || gNutrientes != prevNut) {
    dibujarTiraReles();
  }
}

// =================================================================
// Lee comandos entrantes del ESP8266 por Serial1 (no bloqueante).
void escucharComandos() {
  while (Serial1.available()) {
    char c = (char)Serial1.read();
    if (c == '\n') {
      uartBuf.trim();
      if (uartBuf.length() > 0) aplicarComando(uartBuf);
      uartBuf = "";
    } else if (uartBuf.length() < 32) {
      uartBuf += c;
    }
  }
}

void aplicarComando(const String& cmd) {
  unsigned long t = millis();

  if (cmd == "BOMBA_ON") {
    gBomba = true;
    tFinBomba = t + PULSO_MS;
    digitalWrite(RELE_BOMBA, LOW);
  } else if (cmd == "NUTRIENTES_ON") {
    gNutrientes = true;
    tFinNutrientes = t + PULSO_MS;
    digitalWrite(RELE_NUTRIENTES, LOW);
  } else if (cmd == "LUZ_ON") {
    gLuz = true;  digitalWrite(RELE_LUZ, LOW);
  } else if (cmd == "LUZ_OFF") {
    gLuz = false; digitalWrite(RELE_LUZ, HIGH);
  } else if (cmd == "AUX_ON") {
    gAux = true;  digitalWrite(RELE_AUX, LOW);
  } else if (cmd == "AUX_OFF") {
    gAux = false; digitalWrite(RELE_AUX, HIGH);
  } else {
    Serial.print(F("[MEGA] Comando desconocido: ")); Serial.println(cmd);
    return;
  }
  Serial.print(F("[MEGA] Comando aplicado: ")); Serial.println(cmd);
  dibujarTiraReles();
}

// =================================================================
// Empaqueta telemetría + estado de relés como CSV hacia el ESP8266.
void enviarTelemetria() {
  char buf[64];
  snprintf(buf, sizeof(buf), "%.1f,%.1f,%.2f,%d,%d,%d,%d",
           gTemp, gHum, gPH,
           gBomba ? 1 : 0, gNutrientes ? 1 : 0, gLuz ? 1 : 0, gAux ? 1 : 0);
  Serial1.print(buf);
  Serial1.print('\n');
  Serial.print(F("[MEGA→ESP] ")); Serial.println(buf);
}

// =================================================================
void actualizarDisplay() {
  if (fabs(gPH - prevPH) >= 0.005f) {
    dibujarValorPH();
    moverKnobPH();
    int est = estadoPH(gPH);
    if (est != prevEstado) { dibujarChipEstado(est); prevEstado = est; }
    prevPH = gPH;
  }
  if (dhtOK != prevDhtOK || fabs(gTemp - prevTemp) >= 0.05f) {
    dibujarValorTemp();
    prevTemp = gTemp;
  }
  if (dhtOK != prevDhtOK || fabs(gHum - prevHum) >= 0.05f) {
    dibujarValorHum();
    prevHum = gHum;
  }
  prevDhtOK = dhtOK;
}

// =================================================================
// ESTRUCTURA FIJA
// =================================================================
void dibujarUIEstatica() {
  tft.fillCircle(14, 13, 6, C_VERDE);
  tft.fillCircle(14, 13, 2, C_BG);
  tft.setFont();
  tft.setTextSize(1);
  tft.setCursor(26, 8);
  tft.setTextColor(C_TEXTO); tft.print("Hidro");
  tft.setTextColor(C_TEAL);  tft.print("Smart");
  tft.setTextColor(C_GRIS);
  tft.setCursor(240, 8);
  tft.print("Mega 2560");

  // Tarjeta héroe pH
  tft.fillRoundRect(8, PHC_Y, 304, PHC_H, 12, C_CARD);
  tft.drawRoundRect(8, PHC_Y, 304, PHC_H, 12, C_BORDE);
  tft.setTextSize(1);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(22, PHC_Y + 8);
  tft.print("PH DE LA SOLUCION");

  dibujarGradiente(BAR_X, BAR_X + BAR_W - 1);
  maskEsquinasBarra();

  int x55 = BAR_X + (int)((5.5f - PH_VIS_MIN) / (PH_VIS_MAX - PH_VIS_MIN) * BAR_W);
  int x65 = BAR_X + (int)((6.5f - PH_VIS_MIN) / (PH_VIS_MAX - PH_VIS_MIN) * BAR_W);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(BAR_X - 2,          PHC_Y + 80); tft.print("4");
  tft.setCursor(x55 - 8,            PHC_Y + 80); tft.print("5.5");
  tft.setCursor(x65 - 8,            PHC_Y + 80); tft.print("6.5");
  tft.setCursor(BAR_X + BAR_W - 12, PHC_Y + 80); tft.print("10");

  // Tarjeta temperatura
  tft.fillRoundRect(CT_X, CB_Y, CB_W, CB_H, 12, C_CARD);
  tft.drawRoundRect(CT_X, CB_Y, CB_W, CB_H, 12, C_BORDE);
  iconoTermometro(CT_X + 14, CB_Y + 6);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(CT_X + 36, CB_Y + 10);
  tft.print("TEMPERATURA");

  // Tarjeta humedad
  tft.fillRoundRect(CH_X, CB_Y, CB_W, CB_H, 12, C_CARD);
  tft.drawRoundRect(CH_X, CB_Y, CB_W, CB_H, 12, C_BORDE);
  iconoGota(CH_X + 13, CB_Y + 6);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(CH_X + 36, CB_Y + 10);
  tft.print("HUMEDAD");
}

// =================================================================
// TARJETA pH
void dibujarValorPH() {
  char buf[8];
  dtostrf(gPH, 4, 2, buf);
  char* val = buf;
  while (*val == ' ') val++;

  uint16_t col = colorEstado(estadoPH(gPH));

  tft.fillRect(18, PHC_Y + 22, 200, 34, C_CARD);

  tft.setFont(&FreeSansBold18pt7b);
  tft.setTextSize(1);   // evita heredar escala x2 de las unidades pequeñas
  tft.setTextColor(col);
  tft.setCursor(22, PHC_Y + 50);
  tft.print(val);

  int16_t bx, by; uint16_t bw, bh;
  tft.getTextBounds(val, 22, PHC_Y + 50, &bx, &by, &bw, &bh);
  tft.setFont();
  tft.setTextSize(2);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(22 + bw + 10, PHC_Y + 36);
  tft.print("pH");
}

void dibujarChipEstado(int estado) {
  const char* txt = (estado == 0) ? "IDEAL" : (estado == 1) ? "REVISAR" : "CRITICO";
  uint16_t   col  = colorEstado(estado);

  tft.fillRect(232, PHC_Y + 4, 72, 18, C_CARD);
  int w = strlen(txt) * 6 + 16;
  int x = 304 - w;
  tft.fillRoundRect(x, PHC_Y + 4, w, 18, 9, col);
  tft.setFont();
  tft.setTextSize(1);
  tft.setTextColor(C_BG);
  tft.setCursor(x + 8, PHC_Y + 9);
  tft.print(txt);
}

void moverKnobPH() {
  float phC = constrain(gPH, PH_VIS_MIN, PH_VIS_MAX);
  int x = BAR_X + (int)((phC - PH_VIS_MIN) / (PH_VIS_MAX - PH_VIS_MIN) * BAR_W);
  x = constrain(x, BAR_X + 4, BAR_X + BAR_W - 4);
  if (x == prevKnobX) return;

  if (prevKnobX >= 0) {
    tft.fillRect(prevKnobX - 9, BAR_Y - 6, 19, BAR_H + 12, C_CARD);
    int xa = max(prevKnobX - 9, BAR_X);
    int xb = min(prevKnobX + 9, BAR_X + BAR_W - 1);
    dibujarGradiente(xa, xb);
    maskEsquinasBarra();
  }

  tft.fillCircle(x, BAR_CY, 7, C_TEXTO);
  tft.fillCircle(x, BAR_CY, 3, colorEstado(estadoPH(gPH)));
  prevKnobX = x;
}

void dibujarGradiente(int xa, int xb) {
  for (int x = xa; x <= xb; x++) {
    float ph = PH_VIS_MIN + (float)(x - BAR_X) * (PH_VIS_MAX - PH_VIS_MIN) / BAR_W;
    tft.drawFastVLine(x, BAR_Y, BAR_H, colorSuavePH(ph));
  }
}

void maskEsquinasBarra() {
  int xr = BAR_X + BAR_W - 1;
  int yb = BAR_Y + BAR_H - 1;
  tft.drawPixel(BAR_X, BAR_Y, C_CARD);     tft.drawPixel(BAR_X + 1, BAR_Y, C_CARD);
  tft.drawPixel(BAR_X, BAR_Y + 1, C_CARD);
  tft.drawPixel(xr, BAR_Y, C_CARD);        tft.drawPixel(xr - 1, BAR_Y, C_CARD);
  tft.drawPixel(xr, BAR_Y + 1, C_CARD);
  tft.drawPixel(BAR_X, yb, C_CARD);        tft.drawPixel(BAR_X + 1, yb, C_CARD);
  tft.drawPixel(BAR_X, yb - 1, C_CARD);
  tft.drawPixel(xr, yb, C_CARD);           tft.drawPixel(xr - 1, yb, C_CARD);
  tft.drawPixel(xr, yb - 1, C_CARD);
}

// =================================================================
// TARJETA TEMPERATURA (versión compacta, sin barra de progreso)
void dibujarValorTemp() {
  tft.fillRect(CT_X + 10, CB_Y + 22, 128, 36, C_CARD);

  if (dhtOK) {
    char buf[8];
    dtostrf(gTemp, 4, 1, buf);
    char* val = buf;
    while (*val == ' ') val++;

    tft.setFont(&FreeSansBold18pt7b);
    tft.setTextSize(1);
    tft.setTextColor(C_TEXTO);
    tft.setCursor(CT_X + 14, CB_Y + 50);
    tft.print(val);

    int16_t bx, by; uint16_t bw, bh;
    tft.getTextBounds(val, CT_X + 14, CB_Y + 50, &bx, &by, &bw, &bh);
    tft.setFont();
    tft.setTextSize(2);
    tft.setTextColor(C_NARANJA, C_CARD);
    tft.setCursor(CT_X + 14 + bw + 6, CB_Y + 36);
    tft.print((char)247); tft.print("C");
  } else {
    tft.setFont();
    tft.setTextSize(2);
    tft.setTextColor(C_ROJO, C_CARD);
    tft.setCursor(CT_X + 14, CB_Y + 32);
    tft.print("ERROR");
  }
}

// =================================================================
// TARJETA HUMEDAD (versión compacta)
void dibujarValorHum() {
  tft.fillRect(CH_X + 10, CB_Y + 22, 128, 36, C_CARD);

  if (dhtOK) {
    char buf[8];
    dtostrf(gHum, 4, 1, buf);
    char* val = buf;
    while (*val == ' ') val++;

    tft.setFont(&FreeSansBold18pt7b);
    tft.setTextSize(1);
    tft.setTextColor(C_TEXTO);
    tft.setCursor(CH_X + 14, CB_Y + 50);
    tft.print(val);

    int16_t bx, by; uint16_t bw, bh;
    tft.getTextBounds(val, CH_X + 14, CB_Y + 50, &bx, &by, &bw, &bh);
    tft.setFont();
    tft.setTextSize(2);
    tft.setTextColor(C_AZUL, C_CARD);
    tft.setCursor(CH_X + 14 + bw + 6, CB_Y + 36);
    tft.print("%");
  } else {
    tft.setFont();
    tft.setTextSize(2);
    tft.setTextColor(C_ROJO, C_CARD);
    tft.setCursor(CH_X + 14, CB_Y + 32);
    tft.print("ERROR");
  }
}

// =================================================================
// TIRA DE RELÉS (4 chips: bomba, nutrientes, luz, auxiliar)
void dibujarTiraReles() {
  dibujarChipRele(8,                     "BOMBA",  gBomba);
  dibujarChipRele(8 + REL_W + 4,         "NUTR.",  gNutrientes);
  dibujarChipRele(8 + (REL_W + 4) * 2,   "LUZ",    gLuz);
  dibujarChipRele(8 + (REL_W + 4) * 3,   "AUX",    gAux);
  prevBomba = gBomba; prevNut = gNutrientes; prevLuz = gLuz; prevAux = gAux;
}

void dibujarChipRele(int x, const char* label, bool activo) {
  uint16_t col = activo ? C_VERDE : C_GRIS;
  tft.fillRoundRect(x, RELAY_Y, REL_W, RELAY_H, 10, C_CARD);
  tft.drawRoundRect(x, RELAY_Y, REL_W, RELAY_H, 10, activo ? col : C_BORDE);

  tft.fillCircle(x + 12, RELAY_Y + 12, 4, col);

  tft.setFont();
  tft.setTextSize(1);
  tft.setTextColor(C_GRIS, C_CARD);
  tft.setCursor(x + 22, RELAY_Y + 7);
  tft.print(label);

  tft.setTextColor(col, C_CARD);
  tft.setCursor(x + 8, RELAY_Y + 26);
  tft.print(activo ? "ON" : "OFF");
}

// =================================================================
// ICONOS VECTORIALES
void iconoTermometro(int x, int y) {
  tft.fillRoundRect(x + 3, y + 2, 6, 13, 3, C_NARANJA);
  tft.fillCircle(x + 6, y + 16, 5, C_NARANJA);
  tft.fillRect(x + 5, y + 4, 2, 10, C_CARD);
  tft.fillCircle(x + 6, y + 16, 2, C_CARD);
}

void iconoGota(int x, int y) {
  tft.fillTriangle(x + 7, y, x + 1, y + 12, x + 13, y + 12, C_AZUL);
  tft.fillCircle(x + 7, y + 14, 6, C_AZUL);
  tft.fillCircle(x + 4, y + 13, 2, C_TEXTO);
}

// =================================================================
// HELPERS DE COLOR / ESTADO
int estadoPH(float ph) {
  if (ph >= 5.5f && ph <= 6.5f) return 0;
  if (ph >= 5.0f && ph <= 7.0f) return 1;
  return 2;
}

uint16_t colorEstado(int estado) {
  return (estado == 0) ? C_VERDE : (estado == 1) ? C_AMBAR : C_ROJO;
}

uint16_t rgb565(uint8_t r, uint8_t g, uint8_t b) {
  return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3);
}

uint16_t colorSuavePH(float ph) {
  struct Stop { float p; uint8_t r, g, b; };
  static const Stop stops[] = {
    {4.0f, 248,  81,  73},
    {5.0f, 210, 153,  34},
    {5.5f,  63, 185,  80},
    {6.5f,  63, 185,  80},
    {7.0f, 210, 153,  34},
    {10.0f, 248, 81,  73},
  };
  if (ph <= stops[0].p) return rgb565(stops[0].r, stops[0].g, stops[0].b);
  for (int i = 0; i < 5; i++) {
    if (ph <= stops[i + 1].p) {
      float t = (ph - stops[i].p) / (stops[i + 1].p - stops[i].p);
      uint8_t r = stops[i].r + (int)(t * (stops[i + 1].r - stops[i].r));
      uint8_t g = stops[i].g + (int)(t * (stops[i + 1].g - stops[i].g));
      uint8_t b = stops[i].b + (int)(t * (stops[i + 1].b - stops[i].b));
      return rgb565(r, g, b);
    }
  }
  return rgb565(248, 81, 73);
}
