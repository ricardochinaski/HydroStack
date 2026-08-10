/**
 * HidroSmart — ESP8266 NodeMCU (Gateway WiFi/Firebase)
 * v4.1 — Command protocol v2 foundation.
 *
 * Responsabilidades:
 *  1. Recibe telemetría CSV del Mega por UART y la publica en Firebase.
 *  2. Lee sobres de comando RTDB con commandId + timestamp + TTL.
 *  3. Reenvía cada comando al Mega incluyendo commandId.
 *  4. Reintenta de forma acotada mientras no exista ACK.
 *  5. Publica el ACK real recibido desde el Mega.
 *
 * UART 9600 baud:
 *  Mega → ESP8266 telemetría:
 *    "temp,hum,ph,bomba,nutrientes,luz,aux\n"
 *  ESP8266 → Mega comando v2:
 *    "CMD|<commandId>|<type>|<0|1>\n"
 *  Mega → ESP8266 ACK:
 *    "ACK|<commandId>|<status>|<code>\n"
 *
 * RTDB:
 *  /dispositivos/{DEVICE_ID}/comandos/{actuator}
 *    commandId, value, issuedAt, ttlMs, requestedBy
 *  /dispositivos/{DEVICE_ID}/commandAcks/{actuator}
 *    commandId, status, code, at
 *
 * La autenticación IoT sigue siendo legacy en esta fase y se migrará aparte.
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

// ── IDENTIDAD LEGACY/DEV DEL DISPOSITIVO ─────────────────────────
#define DEVICE_ID       "HS-001"
#define RUTA_TELEMETRIA "/dispositivos/" DEVICE_ID "/telemetria"
#define RUTA_INFO       "/dispositivos/" DEVICE_ID "/info"
#define RUTA_COMANDOS   "/dispositivos/" DEVICE_ID "/comandos"
#define RUTA_ACKS       "/dispositivos/" DEVICE_ID "/commandAcks"

// ── OBJETOS ──────────────────────────────────────────────────────
WiFiUDP        ntpUDP;
NTPClient      timeClient(ntpUDP, "pool.ntp.org", 0); // UTC real

FirebaseData   fbData;
FirebaseData   fbCmd;
FirebaseConfig fbConfig;
FirebaseAuth   fbAuth;

// ── ESTADO RECIBIDO DEL MEGA ─────────────────────────────────────
float gTemp = 0, gHum = 0, gPh = 7.0;
bool  gBomba = false, gNutrientes = false, gLuz = false, gAux = false;

String uartBuf = "";

// ── COMMAND PROTOCOL V2 ──────────────────────────────────────────
static const uint8_t ACTUATOR_COUNT = 4;
const char* ACTUATORS[ACTUATOR_COUNT] = {
  "luz", "auxiliar", "bomba", "nutrientes"
};

String lastSeenId[ACTUATOR_COUNT];
String pendingId[ACTUATOR_COUNT];
String pendingFrame[ACTUATOR_COUNT];
uint64_t pendingExpiresAt[ACTUATOR_COUNT] = {0, 0, 0, 0};
unsigned long pendingLastSend[ACTUATOR_COUNT] = {0, 0, 0, 0};
uint8_t pendingAttempts[ACTUATOR_COUNT] = {0, 0, 0, 0};

const uint8_t MAX_UART_ATTEMPTS = 3;
const unsigned long UART_RETRY_MS = 1500UL;
const unsigned long MIN_VALID_EPOCH = 1700000000UL;

// ── TIMING ────────────────────────────────────────────────────────
const unsigned long T_CLOUD     = 10000UL;
const unsigned long T_CMD_POLL  = 1000UL;
unsigned long tCloud = 0;
unsigned long tCmdPoll = 0;

// =================================================================
void conectarWiFi();
void leerSerialMega();
void parsearCSV(const String& linea);
void parsearAckMega(const String& linea);
void publicarTelemetria();
void sondearComandos();
void procesarSlot(uint8_t index);
void enviarPendiente(uint8_t index);
void reintentarPendientes();
void limpiarPendiente(uint8_t index);
void publicarAck(const char* actuator, const String& commandId,
                 const char* status, const char* code);
void enviarAMega(const String& comando);
String uartTypeFor(const char* actuator);
String epochToISO8601(unsigned long epoch);
uint64_t nowEpochMs();

// =================================================================
void setup() {
  Serial.begin(9600);
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
    info.set("modelo", "HidroSmart Eco (Mega+ESP8266)");
    info.set("fw", "4.1");
    info.set("commandProtocol", "v2");
    info.set("ip", WiFi.localIP().toString());
    info.set("arranque", epochToISO8601(timeClient.getEpochTime()));
    Firebase.setJSON(fbData, RUTA_INFO, info);
  }

  // No inicializar /comandos desde firmware. Un arranque del gateway no debe
  // sobrescribir una solicitud válida escrita por la app.
}

// =================================================================
void loop() {
  leerSerialMega();
  reintentarPendientes();

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
void leerSerialMega() {
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n') {
      uartBuf.trim();
      if (uartBuf.startsWith("ACK|")) {
        parsearAckMega(uartBuf);
      } else if (uartBuf.length() > 0 && uartBuf.indexOf(',') >= 0) {
        parsearCSV(uartBuf);
      }
      uartBuf = "";
    } else if (uartBuf.length() < 128) {
      uartBuf += c;
    }
  }
}

// Formato: "temp,hum,ph,bomba,nutrientes,luz,aux"
void parsearCSV(const String& linea) {
  int idx[6];
  int campo = 0;
  for (int i = 0; i < linea.length() && campo < 6; i++) {
    if (linea[i] == ',') idx[campo++] = i;
  }
  if (campo < 6) return;

  gTemp       = linea.substring(0, idx[0]).toFloat();
  gHum        = linea.substring(idx[0] + 1, idx[1]).toFloat();
  gPh         = linea.substring(idx[1] + 1, idx[2]).toFloat();
  gBomba      = linea.substring(idx[2] + 1, idx[3]).toInt() == 1;
  gNutrientes = linea.substring(idx[3] + 1, idx[4]).toInt() == 1;
  gLuz        = linea.substring(idx[4] + 1, idx[5]).toInt() == 1;
  gAux        = linea.substring(idx[5] + 1).toInt() == 1;
}

// Formato: ACK|commandId|STATUS|CODE
void parsearAckMega(const String& linea) {
  int p1 = linea.indexOf('|');
  int p2 = linea.indexOf('|', p1 + 1);
  int p3 = linea.indexOf('|', p2 + 1);
  if (p1 < 0 || p2 < 0 || p3 < 0) return;

  String commandId = linea.substring(p1 + 1, p2);
  String status = linea.substring(p2 + 1, p3);
  String code = linea.substring(p3 + 1);
  commandId.trim(); status.trim(); code.trim();
  if (commandId.length() == 0) return;

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    if (pendingId[i] == commandId) {
      publicarAck(ACTUATORS[i], commandId, status.c_str(), code.c_str());
      limpiarPendiente(i);
      return;
    }
  }
}

// =================================================================
void publicarTelemetria() {
  if (WiFi.status() != WL_CONNECTED) return;

  timeClient.update();

  FirebaseJson json;
  json.set("ph", gPh);
  json.set("temp_aire", gTemp);
  json.set("humedad", gHum);
  json.set("ec", 0.0);
  json.set("temp_agua", 0.0);
  json.set("nivel_agua", 0.0);
  json.set("relay_bomba", gBomba);
  json.set("relay_nutrientes", gNutrientes);
  json.set("relay_luz", gLuz);
  json.set("relay_auxiliar", gAux);
  json.set("timestamp", epochToISO8601(timeClient.getEpochTime()));

  if (!Firebase.setJSON(fbData, RUTA_TELEMETRIA, json)) {
    Serial.print(F("[Firebase] Error telemetria: "));
    Serial.println(fbData.errorReason());
  }
}

// =================================================================
void sondearComandos() {
  if (WiFi.status() != WL_CONNECTED) return;
  timeClient.update();

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    procesarSlot(i);
  }
}

void procesarSlot(uint8_t index) {
  String base = String(RUTA_COMANDOS) + "/" + ACTUATORS[index];

  if (!Firebase.getString(fbCmd, base + "/commandId")) return;
  String commandId = fbCmd.stringData();
  commandId.trim();
  if (commandId.length() == 0 || commandId == lastSeenId[index]) return;

  // Si aparece una orden más nueva para el mismo actuador, la anterior deja de
  // ser reenviable. Preferimos perder una orden antigua antes que ejecutar dos.
  if (pendingId[index].length() > 0 && pendingId[index] != commandId) {
    publicarAck(ACTUATORS[index], pendingId[index], "REJECTED", "SUPERSEDED");
    limpiarPendiente(index);
  }

  bool value;
  if (!Firebase.getBool(fbCmd, base + "/value")) return;
  value = fbCmd.boolData();

  if (!Firebase.getDouble(fbCmd, base + "/issuedAt")) return;
  uint64_t issuedAt = (uint64_t)fbCmd.doubleData();

  if (!Firebase.getInt(fbCmd, base + "/ttlMs")) return;
  int ttlMs = fbCmd.intData();

  if (!Firebase.getString(fbCmd, base + "/requestedBy")) return;
  String requestedBy = fbCmd.stringData();
  requestedBy.trim();

  lastSeenId[index] = commandId;

  if (requestedBy.length() == 0 || ttlMs < 1000 || ttlMs > 15000 || issuedAt == 0) {
    publicarAck(ACTUATORS[index], commandId, "REJECTED", "INVALID_ENVELOPE");
    return;
  }

  unsigned long epoch = timeClient.getEpochTime();
  if (epoch < MIN_VALID_EPOCH) {
    publicarAck(ACTUATORS[index], commandId, "REJECTED", "TIME_UNSYNCED");
    return;
  }

  uint64_t nowMs = (uint64_t)epoch * 1000ULL;
  uint64_t expiresAt = issuedAt + (uint64_t)ttlMs;
  if (nowMs > expiresAt) {
    publicarAck(ACTUATORS[index], commandId, "EXPIRED", "TTL_EXPIRED");
    return;
  }

  if ((strcmp(ACTUATORS[index], "bomba") == 0 ||
       strcmp(ACTUATORS[index], "nutrientes") == 0) && !value) {
    publicarAck(ACTUATORS[index], commandId, "REJECTED", "INVALID_VALUE");
    return;
  }

  String type = uartTypeFor(ACTUATORS[index]);
  if (type.length() == 0) {
    publicarAck(ACTUATORS[index], commandId, "REJECTED", "UNKNOWN_ACTUATOR");
    return;
  }

  pendingId[index] = commandId;
  pendingFrame[index] = "CMD|" + commandId + "|" + type + "|" + (value ? "1" : "0");
  pendingExpiresAt[index] = expiresAt;
  pendingAttempts[index] = 0;
  pendingLastSend[index] = 0;
  enviarPendiente(index);
}

void enviarPendiente(uint8_t index) {
  if (pendingId[index].length() == 0) return;
  if (pendingAttempts[index] >= MAX_UART_ATTEMPTS) return;

  enviarAMega(pendingFrame[index]);
  pendingAttempts[index]++;
  pendingLastSend[index] = millis();
}

void reintentarPendientes() {
  if (WiFi.status() != WL_CONNECTED) return;

  uint64_t nowMs = nowEpochMs();
  unsigned long t = millis();

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    if (pendingId[i].length() == 0) continue;

    if (nowMs > 0 && nowMs > pendingExpiresAt[i]) {
      publicarAck(ACTUATORS[i], pendingId[i], "EXPIRED", "TTL_EXPIRED_WAITING_ACK");
      limpiarPendiente(i);
      continue;
    }

    if (pendingAttempts[i] >= MAX_UART_ATTEMPTS) {
      if (t - pendingLastSend[i] >= UART_RETRY_MS) {
        publicarAck(ACTUATORS[i], pendingId[i], "REJECTED", "MEGA_NO_ACK");
        limpiarPendiente(i);
      }
      continue;
    }

    if (t - pendingLastSend[i] >= UART_RETRY_MS) {
      enviarPendiente(i);
    }
  }
}

void limpiarPendiente(uint8_t index) {
  pendingId[index] = "";
  pendingFrame[index] = "";
  pendingExpiresAt[index] = 0;
  pendingAttempts[index] = 0;
  pendingLastSend[index] = 0;
}

void publicarAck(const char* actuator, const String& commandId,
                 const char* status, const char* code) {
  if (WiFi.status() != WL_CONNECTED) return;

  FirebaseJson ack;
  ack.set("commandId", commandId);
  ack.set("status", status);
  ack.set("code", code);
  ack.set("at", (double)nowEpochMs());
  Firebase.setJSON(fbData, String(RUTA_ACKS) + "/" + actuator, ack);
}

String uartTypeFor(const char* actuator) {
  if (strcmp(actuator, "luz") == 0) return "LIGHT_SET";
  if (strcmp(actuator, "auxiliar") == 0) return "AUX_SET";
  if (strcmp(actuator, "bomba") == 0) return "PUMP_PULSE";
  if (strcmp(actuator, "nutrientes") == 0) return "NUTRIENTS_PULSE";
  return "";
}

void enviarAMega(const String& comando) {
  Serial.println(comando);
}

uint64_t nowEpochMs() {
  unsigned long epoch = timeClient.getEpochTime();
  if (epoch < MIN_VALID_EPOCH) return 0;
  return (uint64_t)epoch * 1000ULL;
}

// =================================================================
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
