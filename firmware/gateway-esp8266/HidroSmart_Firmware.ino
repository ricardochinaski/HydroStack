/**
 * HidroSmart — ESP8266 NodeMCU (Gateway WiFi/Firebase)
 * v4.2 — Command protocol v2 hardened.
 *
 * Responsabilidades:
 *  1. Recibe telemetría CSV del Mega por UART y la publica en Firebase.
 *  2. Lee commandPointers por actuador y carga el comando inmutable asociado.
 *  3. Valida identidad, timestamp y TTL antes de reenviar al Mega.
 *  4. Mantiene como máximo un comando en vuelo por actuador.
 *  5. Reintenta el mismo commandId de forma acotada.
 *  6. No libera el actuador hasta persistir en RTDB el estado terminal.
 *
 * UART 9600 baud:
 *  Mega → ESP8266 telemetría:
 *    "temp,hum,ph,bomba,nutrientes,luz,aux\n"
 *  ESP8266 → Mega comando v2:
 *    "CMD|<commandId>|<type>|<0|1>\n"
 *  Mega → ESP8266 ACK:
 *    "ACK|<commandId>|<status>|<code>\n"
 *
 * La autenticación IoT sigue siendo legacy en esta fase y se migrará aparte.
 */

#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <NTPClient.h>
#include <WiFiUDP.h>

#define WIFI_SSID      "TU_WIFI_SSID"
#define WIFI_PASSWORD  "TU_WIFI_PASSWORD"
#define FIREBASE_HOST  "TU_FIREBASE_RTDB_HOST"
#define FIREBASE_AUTH  "TU_FIREBASE_LEGACY_TOKEN"

#define DEVICE_ID       "HS-001"
#define RUTA_TELEMETRIA "/dispositivos/" DEVICE_ID "/telemetria"
#define RUTA_INFO       "/dispositivos/" DEVICE_ID "/info"
#define RUTA_COMANDOS   "/dispositivos/" DEVICE_ID "/comandos"
#define RUTA_POINTERS   "/dispositivos/" DEVICE_ID "/commandPointers"
#define RUTA_ACKS       "/dispositivos/" DEVICE_ID "/commandAcks"

WiFiUDP        ntpUDP;
NTPClient      timeClient(ntpUDP, "pool.ntp.org", 0);

FirebaseData   fbData;
FirebaseData   fbCmd;
FirebaseConfig fbConfig;
FirebaseAuth   fbAuth;

float gTemp = 0, gHum = 0, gPh = 7.0;
bool  gBomba = false, gNutrientes = false, gLuz = false, gAux = false;

String uartBuf = "";

static const uint8_t ACTUATOR_COUNT = 4;
const char* ACTUATORS[ACTUATOR_COUNT] = {
  "luz", "auxiliar", "bomba", "nutrientes"
};

String lastSeenId[ACTUATOR_COUNT];
String pendingId[ACTUATOR_COUNT];
String pendingFrame[ACTUATOR_COUNT];
String pendingAckStatus[ACTUATOR_COUNT];
String pendingAckCode[ACTUATOR_COUNT];
uint64_t pendingExpiresAt[ACTUATOR_COUNT] = {0, 0, 0, 0};
unsigned long pendingLastSend[ACTUATOR_COUNT] = {0, 0, 0, 0};
unsigned long pendingAckLastAttempt[ACTUATOR_COUNT] = {0, 0, 0, 0};
uint8_t pendingAttempts[ACTUATOR_COUNT] = {0, 0, 0, 0};

const uint8_t MAX_UART_ATTEMPTS = 3;
const unsigned long UART_RETRY_MS = 1500UL;
const unsigned long ACK_RETRY_MS = 1500UL;
const unsigned long MIN_VALID_EPOCH = 1700000000UL;

const unsigned long T_CLOUD     = 10000UL;
const unsigned long T_CMD_POLL  = 1000UL;
unsigned long tCloud = 0;
unsigned long tCmdPoll = 0;

void conectarWiFi();
void leerSerialMega();
void parsearCSV(const String& linea);
void parsearAckMega(const String& linea);
void publicarTelemetria();
void sondearComandos();
void procesarSlot(uint8_t index);
void enviarPendiente(uint8_t index);
void reintentarPendientes();
void prepararAckTerminal(uint8_t index, const String& commandId,
                         const char* status, const char* code);
bool intentarPersistirAck(uint8_t index);
void limpiarPendiente(uint8_t index);
bool publicarAck(const char* actuator, const String& commandId,
                 const char* status, const char* code);
void enviarAMega(const String& comando);
String uartTypeFor(const char* actuator);
bool commandIdSeguro(const String& commandId);
String epochToISO8601(unsigned long epoch);
uint64_t nowEpochMs();

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
    info.set("fw", "4.2");
    info.set("commandProtocol", "v2");
    info.set("ip", WiFi.localIP().toString());
    info.set("arranque", epochToISO8601(timeClient.getEpochTime()));
    Firebase.setJSON(fbData, RUTA_INFO, info);
  }
}

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

void conectarWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < 15000UL) {
    delay(250);
  }
}

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

void parsearAckMega(const String& linea) {
  int p1 = linea.indexOf('|');
  int p2 = linea.indexOf('|', p1 + 1);
  int p3 = linea.indexOf('|', p2 + 1);
  if (p1 < 0 || p2 < 0 || p3 < 0) return;

  String commandId = linea.substring(p1 + 1, p2);
  String status = linea.substring(p2 + 1, p3);
  String code = linea.substring(p3 + 1);
  commandId.trim();
  status.trim();
  code.trim();
  if (commandId.length() == 0) return;

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    if (pendingId[i] == commandId) {
      // El ACK del Mega es más autoritativo que cualquier estado UNKNOWN que
      // estuviera pendiente de persistir. Detenemos reintentos UART, pero el
      // actuador sigue bloqueado hasta que RTDB confirme este ACK.
      pendingFrame[i] = "";
      pendingExpiresAt[i] = 0;
      pendingAttempts[i] = MAX_UART_ATTEMPTS;
      pendingAckStatus[i] = status;
      pendingAckCode[i] = code;
      pendingAckLastAttempt[i] = 0;
      intentarPersistirAck(i);
      return;
    }
  }
}

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

  Firebase.setJSON(fbData, RUTA_TELEMETRIA, json);
}

void sondearComandos() {
  if (WiFi.status() != WL_CONNECTED) return;
  timeClient.update();

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    procesarSlot(i);
  }
}

void procesarSlot(uint8_t index) {
  // Una orden por actuador permanece en vuelo hasta que su resultado terminal
  // quede persistido. Un pointer nuevo espera; nunca sustituye ambiguamente al
  // comando anterior.
  if (pendingId[index].length() > 0) return;

  String pointerPath = String(RUTA_POINTERS) + "/" + ACTUATORS[index];
  if (!Firebase.getString(fbCmd, pointerPath)) return;

  String commandId = fbCmd.stringData();
  commandId.trim();
  if (commandId.length() == 0 || commandId == lastSeenId[index]) return;

  if (!commandIdSeguro(commandId)) {
    prepararAckTerminal(index, commandId, "REJECTED", "INVALID_ID");
    return;
  }

  String base = String(RUTA_COMANDOS) + "/" + ACTUATORS[index] + "/" + commandId;

  if (!Firebase.getString(fbCmd, base + "/commandId")) return;
  String storedId = fbCmd.stringData();
  storedId.trim();
  if (storedId != commandId) {
    prepararAckTerminal(index, commandId, "REJECTED", "ID_MISMATCH");
    return;
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

  if (requestedBy.length() == 0 || ttlMs < 1000 || ttlMs > 15000 || issuedAt == 0) {
    prepararAckTerminal(index, commandId, "REJECTED", "INVALID_ENVELOPE");
    return;
  }

  unsigned long epoch = timeClient.getEpochTime();
  if (epoch < MIN_VALID_EPOCH) {
    // Tiempo desconocido: no ejecutar y tampoco convertir una dependencia
    // transitoria en un rechazo definitivo.
    return;
  }

  uint64_t nowMs = (uint64_t)epoch * 1000ULL;
  uint64_t expiresAt = issuedAt + (uint64_t)ttlMs;
  if (nowMs > expiresAt) {
    prepararAckTerminal(index, commandId, "EXPIRED", "TTL_EXPIRED");
    return;
  }

  if ((strcmp(ACTUATORS[index], "bomba") == 0 ||
       strcmp(ACTUATORS[index], "nutrientes") == 0) && !value) {
    prepararAckTerminal(index, commandId, "REJECTED", "INVALID_VALUE");
    return;
  }

  String type = uartTypeFor(ACTUATORS[index]);
  if (type.length() == 0) {
    prepararAckTerminal(index, commandId, "REJECTED", "UNKNOWN_ACTUATOR");
    return;
  }

  pendingId[index] = commandId;
  pendingFrame[index] = "CMD|" + commandId + "|" + type + "|" + (value ? "1" : "0");
  pendingExpiresAt[index] = expiresAt;
  pendingAttempts[index] = 0;
  pendingLastSend[index] = 0;
  pendingAckStatus[index] = "";
  pendingAckCode[index] = "";
  pendingAckLastAttempt[index] = 0;
  enviarPendiente(index);
}

void enviarPendiente(uint8_t index) {
  if (pendingId[index].length() == 0) return;
  if (pendingAckStatus[index].length() > 0) return;
  if (pendingAttempts[index] >= MAX_UART_ATTEMPTS) return;

  enviarAMega(pendingFrame[index]);
  pendingAttempts[index]++;
  pendingLastSend[index] = millis();
}

void reintentarPendientes() {
  if (WiFi.status() != WL_CONNECTED) return;

  timeClient.update();
  uint64_t nowMs = nowEpochMs();
  unsigned long t = millis();

  for (uint8_t i = 0; i < ACTUATOR_COUNT; i++) {
    if (pendingId[i].length() == 0) continue;

    // Si ya existe un resultado terminal conocido, no volver a tocar UART.
    // Solo insistir en persistir el ACK en RTDB.
    if (pendingAckStatus[i].length() > 0) {
      if (pendingAckLastAttempt[i] == 0 ||
          t - pendingAckLastAttempt[i] >= ACK_RETRY_MS) {
        intentarPersistirAck(i);
      }
      continue;
    }

    // Una vez enviado al menos una vez ya no podemos afirmar que una ausencia
    // de ACK signifique "no aplicado". Si expira esperando ACK, el resultado es
    // UNKNOWN y la idempotencia del Mega protege los reintentos del mismo ID.
    if (nowMs > 0 && nowMs > pendingExpiresAt[i]) {
      prepararAckTerminal(i, pendingId[i], "UNKNOWN", "TTL_EXPIRED_WAITING_ACK");
      continue;
    }

    if (pendingAttempts[i] >= MAX_UART_ATTEMPTS) {
      if (t - pendingLastSend[i] >= UART_RETRY_MS) {
        prepararAckTerminal(i, pendingId[i], "UNKNOWN", "MEGA_NO_ACK");
      }
      continue;
    }

    if (t - pendingLastSend[i] >= UART_RETRY_MS) {
      enviarPendiente(i);
    }
  }
}

void prepararAckTerminal(uint8_t index, const String& commandId,
                         const char* status, const char* code) {
  pendingId[index] = commandId;
  pendingFrame[index] = "";
  pendingExpiresAt[index] = 0;
  pendingAttempts[index] = MAX_UART_ATTEMPTS;
  pendingLastSend[index] = 0;
  pendingAckStatus[index] = status;
  pendingAckCode[index] = code;
  pendingAckLastAttempt[index] = 0;
  intentarPersistirAck(index);
}

bool intentarPersistirAck(uint8_t index) {
  if (pendingId[index].length() == 0 || pendingAckStatus[index].length() == 0) {
    return false;
  }

  pendingAckLastAttempt[index] = millis();
  if (!publicarAck(
        ACTUATORS[index],
        pendingId[index],
        pendingAckStatus[index].c_str(),
        pendingAckCode[index].c_str())) {
    return false;
  }

  lastSeenId[index] = pendingId[index];
  limpiarPendiente(index);
  return true;
}

void limpiarPendiente(uint8_t index) {
  pendingId[index] = "";
  pendingFrame[index] = "";
  pendingAckStatus[index] = "";
  pendingAckCode[index] = "";
  pendingExpiresAt[index] = 0;
  pendingAttempts[index] = 0;
  pendingLastSend[index] = 0;
  pendingAckLastAttempt[index] = 0;
}

bool publicarAck(const char* actuator, const String& commandId,
                 const char* status, const char* code) {
  if (WiFi.status() != WL_CONNECTED) return false;

  uint64_t atMs = nowEpochMs();
  if (atMs == 0) return false;

  FirebaseJson ack;
  ack.set("commandId", commandId);
  ack.set("status", status);
  ack.set("code", code);
  ack.set("at", (double)atMs);

  return Firebase.setJSON(
    fbData,
    String(RUTA_ACKS) + "/" + actuator + "/" + commandId,
    ack
  );
}

String uartTypeFor(const char* actuator) {
  if (strcmp(actuator, "luz") == 0) return "LIGHT_SET";
  if (strcmp(actuator, "auxiliar") == 0) return "AUX_SET";
  if (strcmp(actuator, "bomba") == 0) return "PUMP_PULSE";
  if (strcmp(actuator, "nutrientes") == 0) return "NUTRIENTS_PULSE";
  return "";
}

bool commandIdSeguro(const String& commandId) {
  if (commandId.length() < 8 || commandId.length() > 23) return false;
  for (uint16_t i = 0; i < commandId.length(); i++) {
    char c = commandId[i];
    bool ok = (c >= 'A' && c <= 'Z') ||
              (c >= 'a' && c <= 'z') ||
              (c >= '0' && c <= '9') ||
              c == '_' || c == '-';
    if (!ok) return false;
  }
  return true;
}

void enviarAMega(const String& comando) {
  Serial.println(comando);
}

uint64_t nowEpochMs() {
  unsigned long epoch = timeClient.getEpochTime();
  if (epoch < MIN_VALID_EPOCH) return 0;
  return (uint64_t)epoch * 1000ULL;
}

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
