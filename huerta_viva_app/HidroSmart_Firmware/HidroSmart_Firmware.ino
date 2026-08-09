/**
 * HidroSmart — ESP8266 NodeMCU (Gateway WiFi/Firebase)
 * v4.0 — Rol simplificado: YA NO tiene sensores ni pantalla propios.
 * El Arduino Mega 2560 concentra ahora el TFT, el DHT22, el potenciómetro
 * y los relés; este ESP8266 es exclusivamente el puente entre el Mega
 * (por UART) e internet (WiFi + Firebase Realtime Database).
 *
 * Responsabilidades:
 *  1. Recibe telemetría CSV del Mega por UART y la publica en Firebase.
 *  2. Sondea Firebase en busca de comandos de la app y los reenvía al
 *     Mega por UART (cierra el canal app → hardware).
 *
 * Protocolo UART (9600 baud):
 *  Mega → ESP8266 (cada 2 s):
 *    "temp,hum,ph,bomba,nutrientes,luz,aux\n"
 *  ESP8266 → Mega (al detectar un comando nuevo en Firebase):
 *    "BOMBA_ON\n" | "NUTRIENTES_ON\n" | "LUZ_ON\n" | "LUZ_OFF\n" | "AUX_ON\n" | "AUX_OFF\n"
 *
 * Esquema Firebase RTDB:
 *  /dispositivos/{DEVICE_ID}/telemetria   ← este firmware escribe (setJSON)
 *  /dispositivos/{DEVICE_ID}/info         ← este firmware escribe (una vez, al arrancar)
 *  /dispositivos/{DEVICE_ID}/comandos     ← la app escribe, este firmware LEE
 *    - luz        (bool, estado sostenido)
 *    - auxiliar   (bool, estado sostenido)
 *    - bomba      (bool, momentáneo: true dispara pulso, luego se resetea a false)
 *    - nutrientes (bool, momentáneo: ídem)
 *
 * Cableado UART con el Mega (divisor de tensión 5V→3.3V en la línea Mega TX):
 *   Mega TX1 (pin 18) ──[R1 10k]──┬──[R2 22k]── GND   → punto medio a ESP8266 RX
 *   Mega RX1 (pin 19) ───────────────────────────────  ESP8266 TX (directo, sin divisor)
 *   GND común obligatoria entre ambas placas.
 *
 * Librerías (Library Manager):
 *  · Firebase ESP8266 Client (Mobizt)
 *  · NTPClient (Fabrice Weinberg)
 */

#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <NTPClient.h>
#include <WiFiUDP.h>

// ── CREDENCIALES ─────────────────────────────────────────────────
#define WIFI_SSID      "TU_WIFI_SSID"
#define WIFI_PASSWORD  "TU_WIFI_PASSWORD"
#define FIREBASE_HOST  "TU_FIREBASE_RTDB_HOST"
#define FIREBASE_AUTH  "TU_FIREBASE_LEGACY_TOKEN"

// ── IDENTIDAD DEL DISPOSITIVO ────────────────────────────────────
#define DEVICE_ID       "HS-001"
#define RUTA_TELEMETRIA "/dispositivos/" DEVICE_ID "/telemetria"
#define RUTA_INFO       "/dispositivos/" DEVICE_ID "/info"
#define RUTA_COMANDOS   "/dispositivos/" DEVICE_ID "/comandos"

// ── OBJETOS ──────────────────────────────────────────────────────
WiFiUDP        ntpUDP;
NTPClient      timeClient(ntpUDP, "pool.ntp.org", -18000); // UTC-5

FirebaseData   fbData;
FirebaseData   fbCmd;     // handle separado para no chocar con el de telemetría
FirebaseConfig fbConfig;
FirebaseAuth   fbAuth;

// ── ESTADO RECIBIDO DEL MEGA (última telemetría) ─────────────────
float gTemp = 0, gHum = 0, gPh = 7.0;
bool  gBomba = false, gNutrientes = false, gLuz = false, gAux = false;

// ── ESTADO DE COMANDOS (para no repetir toggles ya aplicados) ────
bool lastLuz = false, lastAux = false;
bool comandosInicializados = false;

String uartBuf = "";

// ── TIMING ────────────────────────────────────────────────────────
const unsigned long T_CLOUD     = 10000UL;  // publicar telemetría
const unsigned long T_CMD_POLL  = 3000UL;   // sondear comandos
unsigned long tCloud = 0;
unsigned long tCmdPoll = 0;

// =================================================================
void conectarWiFi();
void leerSerialMega();
void parsearCSV(const String& linea);
void publicarTelemetria();
void sondearComandos();
void enviarAMega(const char* comando);
String epochToISO8601(unsigned long epoch);

// =================================================================
void setup() {
  Serial.begin(9600);
  // Reubica el UART de hardware a GPIO15(TX)/GPIO13(RX), liberando
  // GPIO1/GPIO3 (USB) para depuración por el monitor serie.
  Serial.swap();

  conectarWiFi();

  timeClient.begin();
  timeClient.update();

  fbConfig.host = FIREBASE_HOST;
  fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);

  if (WiFi.status() == WL_CONNECTED) {
    FirebaseJson info;
    info.set("modelo",   "HidroSmart Eco (Mega+ESP8266)");
    info.set("fw",       "4.0");
    info.set("ip",       WiFi.localIP().toString());
    info.set("arranque", epochToISO8601(timeClient.getEpochTime()));
    Firebase.setJSON(fbData, RUTA_INFO, info);

    // Inicializa el nodo de comandos si no existe, para que la app
    // tenga un estado consistente desde el primer momento.
    FirebaseJson cmdInit;
    cmdInit.set("luz", false);
    cmdInit.set("auxiliar", false);
    cmdInit.set("bomba", false);
    cmdInit.set("nutrientes", false);
    Firebase.setJSON(fbData, RUTA_COMANDOS, cmdInit);
  }
}

// =================================================================
void loop() {
  leerSerialMega();

  unsigned long t = millis();

  if (t - tCloud >= T_CLOUD) {
    tCloud = t;
    publicarTelemetria();
  }

  if (t - tCmdPoll >= T_CMD_POLL) {
    tCmdPoll = t;
    sondearComandos();
  }
}

// =================================================================
void conectarWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < 15000UL) {
    delay(250);
  }
}

// =================================================================
// Acumula bytes del Mega hasta '\n' y parsea el CSV de telemetría.
void leerSerialMega() {
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n') {
      uartBuf.trim();
      if (uartBuf.length() > 0 && uartBuf.indexOf(',') >= 0) {
        parsearCSV(uartBuf);
      }
      uartBuf = "";
    } else if (uartBuf.length() < 64) {
      uartBuf += c;
    }
  }
}

// Formato: "temp,hum,ph,bomba,nutrientes,luz,aux"
void parsearCSV(const String& linea) {
  int idx[6];
  int pos = 0, campo = 0;
  for (int i = 0; i < linea.length() && campo < 6; i++) {
    if (linea[i] == ',') { idx[campo++] = i; }
  }
  if (campo < 6) return; // trama incompleta, descartar

  gTemp       = linea.substring(0, idx[0]).toFloat();
  gHum        = linea.substring(idx[0] + 1, idx[1]).toFloat();
  gPh         = linea.substring(idx[1] + 1, idx[2]).toFloat();
  gBomba      = linea.substring(idx[2] + 1, idx[3]).toInt() == 1;
  gNutrientes = linea.substring(idx[3] + 1, idx[4]).toInt() == 1;
  gLuz        = linea.substring(idx[4] + 1, idx[5]).toInt() == 1;
  gAux        = linea.substring(idx[5] + 1).toInt() == 1;
}

// =================================================================
void publicarTelemetria() {
  if (WiFi.status() != WL_CONNECTED) return;

  FirebaseJson json;
  json.set("ph",              gPh);
  json.set("temp_aire",       gTemp);
  json.set("humedad",         gHum);
  json.set("ec",              0.0);   // placeholder: sin sensor EC aún
  json.set("temp_agua",       0.0);   // placeholder: sin DS18B20 aún
  json.set("nivel_agua",      0.0);   // placeholder: sin HC-SR04 aún
  json.set("relay_bomba",      gBomba);
  json.set("relay_nutrientes", gNutrientes);
  json.set("relay_luz",        gLuz);
  json.set("relay_auxiliar",   gAux);
  json.set("timestamp",       epochToISO8601(timeClient.getEpochTime()));

  // setJSON (PUT) reemplaza el nodo completo, sin dejar claves huérfanas.
  if (!Firebase.setJSON(fbData, RUTA_TELEMETRIA, json)) {
    Serial.print(F("[Firebase] Error telemetria: "));
    Serial.println(fbData.errorReason());
  }
}

// =================================================================
// Lee el nodo de comandos y reenvía al Mega solo lo que cambió
// (toggles) o lo que llegó activado (momentáneos), consumiéndolo
// después para permitir un nuevo disparo posterior.
void sondearComandos() {
  if (WiFi.status() != WL_CONNECTED) return;

  bool luz = lastLuz, aux = lastAux;

  if (Firebase.getBool(fbCmd, String(RUTA_COMANDOS) + "/luz"))      luz = fbCmd.boolData();
  if (Firebase.getBool(fbCmd, String(RUTA_COMANDOS) + "/auxiliar")) aux = fbCmd.boolData();

  if (!comandosInicializados) {
    // Primera lectura: adopta el estado tal cual está en Firebase,
    // sin disparar un cambio hacia el Mega (evita un toggle fantasma
    // al arrancar).
    lastLuz = luz; lastAux = aux;
    comandosInicializados = true;
  } else {
    if (luz != lastLuz) { enviarAMega(luz ? "LUZ_ON" : "LUZ_OFF"); lastLuz = luz; }
    if (aux != lastAux) { enviarAMega(aux ? "AUX_ON" : "AUX_OFF"); lastAux = aux; }
  }

  // Comandos momentáneos: si están en true, disparan el pulso en el
  // Mega y se resetean a false en Firebase para permitir un reintento.
  if (Firebase.getBool(fbCmd, String(RUTA_COMANDOS) + "/bomba") && fbCmd.boolData()) {
    enviarAMega("BOMBA_ON");
    Firebase.setBool(fbData, String(RUTA_COMANDOS) + "/bomba", false);
  }
  if (Firebase.getBool(fbCmd, String(RUTA_COMANDOS) + "/nutrientes") && fbCmd.boolData()) {
    enviarAMega("NUTRIENTES_ON");
    Firebase.setBool(fbData, String(RUTA_COMANDOS) + "/nutrientes", false);
  }
}

void enviarAMega(const char* comando) {
  Serial.println(comando);  // UART (recuerda: Serial.swap() ya movió esto a GPIO15/13)
}

// =================================================================
// Convierte epoch Unix a "YYYY-MM-DDTHH:MM:SSZ"
String epochToISO8601(unsigned long epoch) {
  static const uint8_t dim[] = {31,28,31,30,31,30,31,31,30,31,30,31};

  unsigned long t = epoch;
  unsigned long ss = t % 60; t /= 60;
  unsigned long mm = t % 60; t /= 60;
  unsigned long hh = t % 24; t /= 24;

  unsigned long yr = 1970;
  while (true) {
    bool bisiesto = (yr % 4 == 0 && (yr % 100 != 0 || yr % 400 == 0));
    unsigned long diy = bisiesto ? 366UL : 365UL;
    if (t < diy) break;
    t -= diy;
    yr++;
  }

  bool bisiesto = (yr % 4 == 0 && (yr % 100 != 0 || yr % 400 == 0));
  unsigned long mo = 1;
  for (int i = 0; i < 12; i++) {
    unsigned long d = dim[i] + (i == 1 && bisiesto ? 1 : 0);
    if (t < d) { mo = i + 1; break; }
    t -= d;
  }
  unsigned long dy = t + 1;

  char buf[25];
  snprintf(buf, sizeof(buf), "%04lu-%02lu-%02luT%02lu:%02lu:%02luZ",
           yr, mo, dy, hh, mm, ss);
  return String(buf);
}
