/*
 * CalendarioFamiliar.ino
 * Panel de calendario familiar para ESP32 + TFT 2.4" mcufriend (ILI9341)
 *
 * Abre este archivo con Arduino IDE y haz Upload directo por USB.
 *
 * REQUISITOS previos (leer antes de flashear):
 *
 * 1. Instalar librerias en Arduino IDE (Sketch -> Include Library -> Manage Libraries):
 *    - "TFT_eSPI" by Bodmer (v2.5.43+)
 *    - "ArduinoJson" by Benoit Blanchon (v7.x)
 *
 * 2. Configurar TFT_eSPI: Copia el archivo User_Setup.h que viene con este proyecto a:
 *    C:\Users\ricar\Documents\Arduino\libraries\TFT_eSPI\User_Setup.h
 *    (reemplaza el existente)
 *
 * 3. Edita la seccion CONFIGURACION mas abajo con tus credenciales WiFi.
 *
 * 4. Placa en Arduino IDE: "ESP32 Dev Module" (o la que tengas)
 */

// ============================================================
// CONFIGURACION DEL USUARIO  <-- MODIFICA ESTO
// ============================================================

// ---- WiFi ----
#define WIFI_SSID     "TU_WIFI_SSID"
#define WIFI_PASSWORD "TU_WIFI_PASSWORD"

// ---- Modo demo ----
// 1 = datos de prueba locales (no necesita internet para eventos)
// 0 = conecta a Google Calendar real via Google Apps Script
#define DEMO_MODE 1

// ---- Google Apps Script (solo si DEMO_MODE=0) ----
#define CALENDAR_API_URL "https://script.google.com/macros/s/TU_DEPLOYMENT_ID/exec"

// ---- Zona horaria (UTC offset) ----
#define TZ_OFFSET_HOURS  -6     // -6 = Mexico City, -4 = Santiago, -3 = Buenos Aires
#define TZ_DST_ACTIVE    0      // 1 = horario de verano activo

// ---- Ciclo de actualizacion ----
#define CALENDAR_UPDATE_INTERVAL_SEC 900   // 900s = 15 minutos
#define VIEW_CYCLE_SEC 30                  // cada 30s alterna entre vista Hoy/Semana

// ---- Pantalla ----
#define BACKLIGHT_TIMEOUT_SEC 120          // apagar backlight tras inactividad (0=nunca)

// ---- Power ----
#define ENABLE_SLEEP false                 // true = light sleep entre updates

// ---- Debug por Serial ----
#define DEBUG_ENABLED 1

// ============================================================
// NO MODIFICAR DEBAJO DE ESTA LINEA
// ============================================================

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <TFT_eSPI.h>
#include <time.h>

// --- Macros debug ---
#if DEBUG_ENABLED
  #define DPRINT(x)   Serial.print(x)
  #define DPRINTLN(x) Serial.println(x)
  #define DPRINTF(f,...) Serial.printf(f, ##__VA_ARGS__)
#else
  #define DPRINT(x)
  #define DPRINTLN(x)
  #define DPRINTF(f,...)
#endif

// --- Constantes ---
#define PIN_LED_STATUS     32
#define MAX_EVENTS_PER_DAY 10
#define MAX_DAYS           7
#define MAX_JSON_BUFFER    8192
#define NTP_SYNC_INTERVAL  43200  // 12h
#define HTTP_TIMEOUT_MS    15000
#define SLEEP_DURATION_SEC 600

// ============================================================
// ESTRUCTURAS DE DATOS
// ============================================================
struct CalendarEvent {
  char title[64];
  char time[8];
  char end[8];
  char location[32];
  bool allDay;
  int  colorIdx;
};

struct DayEvents {
  char date[12];
  char weekday[6];
  int  eventCount;
  CalendarEvent events[MAX_EVENTS_PER_DAY];
};

// ============================================================
// PALETA DE COLORES (RGB565)
// ============================================================
#define C_BG           TFT_BLACK
#define C_HEADER_BG    0x2104
#define C_CARD_BG      0x1082
#define C_TEXT_PRIMARY TFT_WHITE
#define C_TEXT_SEC     0xBDF7
#define C_TITLE        TFT_YELLOW
#define C_HIGHLIGHT    0xFD20
#define C_EVENT_DOT    0x07E0

static const uint16_t EVENT_COLORS[8] = {
  0x07E0, 0xFD20, 0x07FF, 0xF81F, 0xFFE0, 0x001F, 0xF800, 0x780F
};

// ============================================================
// WIFI MANAGER
// ============================================================
class WifiManager {
  unsigned long lastCheckMs = 0;
  static const unsigned long CHECK_MS = 30000;
public:
  bool connect() {
    DPRINT(F("[WiFi] Conectando a ")); DPRINTLN(WIFI_SSID);
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(true);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    int tries = 0;
    while (WiFi.status() != WL_CONNECTED && tries < 30) {
      delay(1000); tries++; DPRINT(F("."));
    }
    DPRINTLN();
    if (WiFi.status() == WL_CONNECTED) {
      DPRINT(F("[WiFi] OK. IP: ")); DPRINTLN(WiFi.localIP());
      return true;
    }
    DPRINTLN(F("[WiFi] ERROR"));
    return false;
  }
  bool isConnected() { return WiFi.status() == WL_CONNECTED; }
  bool maintain() {
    if (WiFi.status() == WL_CONNECTED) { lastCheckMs = millis(); return true; }
    if (millis() - lastCheckMs > CHECK_MS) {
      DPRINTLN(F("[WiFi] Reconectando..."));
      WiFi.disconnect(); delay(1000);
      return connect();
    }
    return false;
  }
  int getRSSI() { return WiFi.RSSI(); }
};

// ============================================================
// TIME SYNC (NTP)
// ============================================================
class TimeSync {
  bool synced = false;
  unsigned long lastSyncEpoch = 0;
public:
  bool sync() {
    DPRINTLN(F("[NTP] Sincronizando..."));
    configTime(TZ_OFFSET_HOURS * 3600L, TZ_DST_ACTIVE ? 3600 : 0,
               "pool.ntp.org", "time.google.com");
    struct tm ti;
    int tries = 0;
    while (!getLocalTime(&ti) && tries < 20) { delay(500); tries++; DPRINT(F(".")); }
    DPRINTLN();
    if (tries >= 20) { DPRINTLN(F("[NTP] ERROR")); synced = false; return false; }
    lastSyncEpoch = mktime(&ti);
    synced = true;
    DPRINTF("[NTP] %02d:%02d %02d/%02d/%04d\n",
            ti.tm_hour, ti.tm_min, ti.tm_mday, ti.tm_mon + 1, ti.tm_year + 1900);
    return true;
  }
  bool maintain() {
    if (!synced) return sync();
    time_t n; time(&n);
    if (n - lastSyncEpoch > NTP_SYNC_INTERVAL) return sync();
    return true;
  }
  bool getNow(struct tm* out) { return synced && getLocalTime(out, 0); }
  bool isSynced() { return synced; }
  void fmtTime(char* buf, size_t sz, struct tm* t) { snprintf(buf, sz, "%02d:%02d", t->tm_hour, t->tm_min); }
  void fmtDate(char* buf, size_t sz, struct tm* t) { snprintf(buf, sz, "%02d/%02d", t->tm_mday, t->tm_mon + 1); }
};

// ============================================================
// CALENDAR FETCHER
// ============================================================
class CalendarFetcher {
  HTTPClient http;
  DayEvents days[MAX_DAYS];
  int dayCount = 0, totalEvents = 0;
  char lastError[64] = "";
  bool dataValid = false;

  void clearAll() {
    dayCount = totalEvents = 0;
    for (int i = 0; i < MAX_DAYS; i++) memset(&days[i], 0, sizeof(DayEvents));
  }
  void sc(char* dst, size_t sz, const char* src) {
    if (src) { strncpy(dst, src, sz - 1); dst[sz - 1] = '\0'; } else dst[0] = '\0';
  }
  bool addEvent(int di, const char* title, const char* time, const char* end,
                bool allDay, int ci, const char* loc = "") {
    if (di < 0 || di >= dayCount || days[di].eventCount >= MAX_EVENTS_PER_DAY) return false;
    CalendarEvent& e = days[di].events[days[di].eventCount];
    sc(e.title, 64, title); sc(e.time, 8, time); sc(e.end, 8, end);
    sc(e.location, 32, loc); e.allDay = allDay; e.colorIdx = ci;
    days[di].eventCount++; totalEvents++; return true;
  }

  void loadDemo() {
    clearAll(); dayCount = MAX_DAYS;
    const char* wd[] = {"DOM","LUN","MAR","MIE","JUE","VIE","SAB"};
    time_t now = time(nullptr);
    for (int i = 0; i < MAX_DAYS; i++) {
      time_t dt = now + i * 86400; struct tm* d = localtime(&dt);
      snprintf(days[i].date, 12, "%04d-%02d-%02d", d->tm_year + 1900, d->tm_mon + 1, d->tm_mday);
      sc(days[i].weekday, 6, wd[d->tm_wday]);
    }
    // Dia 0 (HOY)
    addEvent(0, "Reunion trabajo",     "09:00","10:00",false,5, "Oficina");
    addEvent(0, "Clase piano Juan",    "14:30","15:30",false,0);
    addEvent(0, "Supermercado",        "17:00","18:00",false,1);
    addEvent(0, "Cena familiar",       "20:00","21:30",false,3, "Casa");
    // Dia 1
    addEvent(1, "Gimnasio",            "07:00","08:00",false,0);
    addEvent(1, "Pediatra Ana",        "11:30","12:15",false,6);
    addEvent(1, "Cumpleanos Abuela",   "","",true,4);
    // Dia 2
    addEvent(2, "Futbol Pedro",        "16:00","18:00",false,0, "Cancha Municipal");
    addEvent(2, "Pagar facturas",      "","",true,1);
    // Dia 3
    addEvent(3, "Paseo familiar",      "","",true,7);
    addEvent(3, "Comprar regalo",      "10:00","11:00",false,4);
    // Dia 4
    addEvent(4, "Dentista",            "08:30","09:30",false,2);
    addEvent(4, "Reunion escolar",     "18:00","19:00",false,5);
    // Dia 5
    addEvent(5, "Yoga",                "06:30","07:30",false,7);
    // Dia 6
    addEvent(6, "Cine en familia",     "19:00","21:00",false,3, "Plaza Central");

    dataValid = true;
    DPRINTF("[Demo] %d dias, %d eventos\n", dayCount, totalEvents);
  }

public:
  bool fetch(WifiManager& wifi) {
    #if DEMO_MODE
      DPRINTLN(F("[Fetch] MODO DEMO"));
      loadDemo();
      return true;
    #else
      if (!wifi.isConnected()) { snprintf(lastError, 64, "WiFi off"); return false; }
      clearAll();
      DPRINTF("[Fetch] URL: %s\n", CALENDAR_API_URL);
      http.begin(CALENDAR_API_URL);
      http.setTimeout(HTTP_TIMEOUT_MS);
      int code = http.GET();
      if (code == 301 || code == 302) {
        String redir = http.header("Location");
        http.end(); http.begin(redir); http.setTimeout(HTTP_TIMEOUT_MS);
        code = http.GET();
      }
      if (code != 200) {
        snprintf(lastError, 64, "HTTP %d", code);
        DPRINTF("[Fetch] ERROR: %d\n", code);
        http.end(); return false;
      }
      String payload = http.getString(); http.end();
      if (payload.length() == 0) {
        snprintf(lastError, 64, "Respuesta vacia");
        return false;
      }
      DPRINTF("[Fetch] %d bytes\n", payload.length());
      bool ok = parse(payload);
      dataValid = ok;
      return ok;
    #endif
  }

  bool parse(String& json) {
    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, json);
    if (err) { snprintf(lastError, 64, "JSON: %s", err.c_str()); return false; }
    const char* st = doc["status"];
    if (!st || strcmp(st, "ok") != 0) { snprintf(lastError, 64, "Status no ok"); return false; }
    totalEvents = doc["totalEvents"] | 0;
    JsonArray arr = doc["days"].as<JsonArray>();
    if (!arr) { snprintf(lastError, 64, "Sin array days"); return false; }
    dayCount = 0;
    for (JsonObject d : arr) {
      if (dayCount >= MAX_DAYS) break;
      DayEvents& day = days[dayCount];
      sc(day.date, 12, d["date"]); sc(day.weekday, 6, d["weekday"]);
      JsonArray evts = d["events"].as<JsonArray>();
      day.eventCount = 0;
      if (evts) {
        for (JsonObject e : evts) {
          if (day.eventCount >= MAX_EVENTS_PER_DAY) break;
          CalendarEvent& ev = day.events[day.eventCount];
          sc(ev.title, 64, e["title"]); sc(ev.time, 8, e["time"]);
          sc(ev.end, 8, e["end"]); sc(ev.location, 32, e["location"]);
          ev.allDay = e["allday"] | false; ev.colorIdx = e["colorIdx"] | -1;
          day.eventCount++;
        }
      }
      dayCount++;
    }
    DPRINTF("[Parse] OK: %d dias, %d eventos, %d bytes RAM\n",
            dayCount, totalEvents, doc.memoryUsage());
    return true;
  }

  // Getters
  int getDayCount()    { return dayCount; }
  int getTotalEvents() { return totalEvents; }
  bool isValid()       { return dataValid; }
  DayEvents* getDay(int i) { return (i >= 0 && i < dayCount) ? &days[i] : nullptr; }
  DayEvents* getToday()    { return dayCount > 0 ? &days[0] : nullptr; }
  const char* getLastError() { return lastError; }
};

// ============================================================
// SCREEN RENDERER
// ============================================================
class ScreenRenderer {
  TFT_eSPI& tft;
  int currentView = 0;
  static const int HEADER_H = 28, FOOTER_H = 20, MARGIN = 4;

  void drawHeader(const char* title, TimeSync& ts) {
    tft.fillRect(0, 0, 320, HEADER_H, C_HEADER_BG);
    tft.setTextColor(C_TEXT_PRIMARY, C_HEADER_BG);
    tft.setTextFont(2); tft.setTextDatum(TL_DATUM);
    tft.drawString(title, MARGIN, 4);
    struct tm now;
    if (ts.getNow(&now)) {
      char tb[10]; ts.fmtTime(tb, sizeof(tb), &now);
      tft.setTextDatum(TR_DATUM);
      tft.drawString(tb, 320 - MARGIN, 4);
    }
    tft.drawFastHLine(0, HEADER_H - 1, 320, 0x4208);
  }

  void drawFooter(const char* status, int rssi) {
    tft.fillRect(0, 240 - FOOTER_H, 320, FOOTER_H, C_HEADER_BG);
    tft.drawFastHLine(0, 240 - FOOTER_H, 320, 0x4208);
    tft.setTextColor(C_TEXT_SEC, C_HEADER_BG);
    tft.setTextFont(1); tft.setTextDatum(BL_DATUM);
    tft.drawString(status, MARGIN, 240 - FOOTER_H + 1);
    char rs[12]; snprintf(rs, 12, "WiFi %d", rssi);
    tft.setTextDatum(BR_DATUM);
    tft.drawString(rs, 320 - MARGIN, 240 - FOOTER_H + 1);
  }

  void drawToday(DayEvents* today, TimeSync& ts, int rssi) {
    int y = HEADER_H + MARGIN;
    struct tm now; ts.getNow(&now);
    char db[24];
    snprintf(db, 24, "%s %02d/%02d",
             (const char*[]){"DOM","LUN","MAR","MIE","JUE","VIE","SAB"}[now.tm_wday],
             now.tm_mday, now.tm_mon + 1);
    tft.setTextColor(C_HIGHLIGHT, C_BG);
    tft.setTextFont(4); tft.setTextDatum(TC_DATUM);
    tft.drawString(db, 160, y);
    y += tft.fontHeight() + MARGIN * 2;

    if (!today || today->eventCount == 0) {
      tft.setTextColor(C_TEXT_SEC, C_BG);
      tft.setTextFont(2); tft.setTextDatum(TC_DATUM);
      tft.drawString("Sin eventos hoy", 160, y + 20);
      drawFooter("Sin eventos", rssi);
      return;
    }
    tft.setTextFont(2);
    int maxEv = (240 - y - FOOTER_H - MARGIN) / 32;
    for (int i = 0; i < today->eventCount && i < maxEv; i++) {
      CalendarEvent& e = today->events[i];
      int ey = y + i * 32;
      uint16_t bc = e.colorIdx >= 0 && e.colorIdx < 8 ? EVENT_COLORS[e.colorIdx] : C_EVENT_DOT;
      tft.fillRect(MARGIN, ey, 4, 26, bc);
      tft.fillRoundRect(MARGIN + 5, ey, 320 - MARGIN * 2 - 5, 26, 4, C_CARD_BG);
      tft.setTextColor(C_TITLE, C_CARD_BG);
      tft.setTextDatum(TL_DATUM);
      tft.drawString(e.allDay ? "TODO" : e.time, MARGIN + 12, ey + 4);
      tft.setTextColor(C_TEXT_PRIMARY, C_CARD_BG);
      tft.drawString(e.title, MARGIN + 68, ey + 4);
      if (!e.allDay && e.end[0]) {
        char eb[16]; snprintf(eb, 16, "-%s", e.end);
        tft.setTextColor(C_TEXT_SEC, C_CARD_BG);
        tft.drawString(eb, MARGIN + 68, ey + 14);
      }
    }
    char fb[32]; snprintf(fb, 32, "%d evento(s)", today->eventCount);
    drawFooter(fb, rssi);
  }

  void drawWeek(CalendarFetcher& cal, TimeSync& ts, int rssi) {
    int y = HEADER_H + MARGIN;
    tft.setTextColor(C_TEXT_PRIMARY, C_BG);
    tft.setTextFont(2); tft.setTextDatum(TL_DATUM);
    tft.drawString("Proximos dias", MARGIN, y);
    y += 16 + MARGIN;
    int nd = cal.getDayCount();
    int cw = (320 - MARGIN * 2 - (nd - 1) * 2) / nd;
    if (cw < 36) cw = 36;
    int ch = 240 - y - FOOTER_H - MARGIN;
    for (int d = 0; d < nd; d++) {
      DayEvents* day = cal.getDay(d); if (!day) continue;
      int x = MARGIN + d * (cw + 2);
      bool isToday = (d == 0);
      uint16_t bg = isToday ? C_HEADER_BG : C_CARD_BG;
      tft.fillRoundRect(x, y, cw, ch, 4, bg);
      if (isToday) tft.drawRoundRect(x - 1, y - 1, cw + 2, ch + 2, 4, C_HIGHLIGHT);
      tft.setTextColor(isToday ? TFT_YELLOW : C_TEXT_SEC, bg);
      tft.setTextFont(1); tft.setTextDatum(TC_DATUM);
      tft.drawString(day->weekday, x + cw / 2, y + 4);
      const char* dash = strrchr(day->date, '-');
      char dn[4] = "??";
      if (dash) { dn[0] = dash[1]; dn[1] = dash[2]; dn[2] = '\0'; }
      tft.setTextColor(C_TEXT_PRIMARY, bg);
      tft.setTextFont(2);
      tft.drawString(dn, x + cw / 2, y + 14);
      int ey = y + 32;
      int maxDisp = (ch - 36) / 10;
      for (int e = 0; e < day->eventCount && e < maxDisp; e++) {
        CalendarEvent& ev = day->events[e];
        uint16_t dc = ev.colorIdx >= 0 && ev.colorIdx < 8 ? EVENT_COLORS[ev.colorIdx] : C_EVENT_DOT;
        if (maxDisp <= 6) {
          tft.setTextColor(C_TEXT_PRIMARY, bg);
          tft.setTextFont(1); tft.setTextDatum(TL_DATUM);
          char abbr[20]; strncpy(abbr, ev.title, 19); abbr[19] = '\0';
          if (strlen(abbr) > (size_t)(cw / 6)) abbr[cw / 6] = '\0';
          tft.fillCircle(x + 5, ey + 4, 3, dc);
          tft.drawString(abbr, x + 12, ey);
          ey += 12;
        } else {
          tft.fillCircle(x + cw / 2, ey, 3, dc);
          ey += 10;
        }
      }
      if (day->eventCount > maxDisp) {
        tft.setTextColor(C_TEXT_SEC, bg);
        tft.setTextFont(1); tft.setTextDatum(BC_DATUM);
        char more[8]; snprintf(more, 8, "+%d", day->eventCount - maxDisp);
        tft.drawString(more, x + cw / 2, y + ch - 8);
      }
    }
    char fb[32]; snprintf(fb, 32, "%d eventos", cal.getTotalEvents());
    drawFooter(fb, rssi);
  }

  void drawError(const char* title, const char* msg) {
    tft.fillScreen(C_BG);
    tft.fillRect(0, 0, 320, HEADER_H, C_HEADER_BG);
    tft.setTextColor(TFT_RED, C_HEADER_BG);
    tft.setTextFont(2); tft.setTextDatum(TC_DATUM);
    tft.drawString(title, 160, 4);
    tft.setTextColor(C_TEXT_PRIMARY, C_BG);
    tft.setTextFont(2); tft.setTextDatum(MC_DATUM);
    if (msg) {
      char lb[36]; int ly = 100, li = 0;
      for (const char* p = msg; *p && ly < 200; p++) {
        if (*p == '\n' || li >= 28) {
          lb[li] = '\0'; tft.drawString(lb, 160, ly); ly += 18; li = 0;
          if (*p == '\n') continue;
        }
        lb[li++] = *p;
      }
      if (li > 0) { lb[li] = '\0'; tft.drawString(lb, 160, ly); }
    }
    char fb[32]; snprintf(fb, 32, "Reintentando...");
    drawFooter(fb, 0);
  }

public:
  ScreenRenderer(TFT_eSPI& r) : tft(r) {}
  void begin() { tft.init(); tft.setRotation(1); tft.fillScreen(C_BG); }

  void showSplash(const char* status) {
    tft.fillScreen(C_BG);
    tft.setTextColor(C_HIGHLIGHT, C_BG);
    tft.setTextFont(4); tft.setTextDatum(MC_DATUM);
    tft.drawString("CALENDARIO", 160, 80);
    tft.drawString("FAMILIAR", 160, 120);
    tft.setTextColor(C_TEXT_SEC, C_BG);
    tft.setTextFont(2); tft.setTextDatum(TC_DATUM);
    tft.drawString(status, 160, 170);
  }

  void showError(const char* title, const char* msg) { drawError(title, msg); }

  void render(CalendarFetcher& cal, TimeSync& ts, int rssi, const char* status) {
    if (!cal.isValid()) { showError("Error datos", "Sin datos del calendario."); return; }
    tft.fillScreen(C_BG);
    if (currentView == 0) { drawHeader("Hoy", ts); drawToday(cal.getToday(), ts, rssi); }
    else                  { drawHeader("Semana", ts); drawWeek(cal, ts, rssi); }
  }

  void setView(int v) { if (v == 0 || v == 1) currentView = v; }
  int getCurrentView() { return currentView; }
  void backlightOff() { tft.fillScreen(TFT_BLACK); }
};

// ============================================================
// POWER MANAGER
// ============================================================
class PowerManager {
  unsigned long lastActivityMs = 0;
  bool backlightOn = true;
public:
  void begin() {
    pinMode(PIN_LED_STATUS, OUTPUT);
    digitalWrite(PIN_LED_STATUS, LOW);
    lastActivityMs = millis();
  }
  void markActivity() { lastActivityMs = millis(); digitalWrite(PIN_LED_STATUS, HIGH); }
  void checkIdle() {
    if (BACKLIGHT_TIMEOUT_SEC && backlightOn &&
        millis() - lastActivityMs > BACKLIGHT_TIMEOUT_SEC * 1000UL) {
      backlightOn = false;
    }
  }
  void lightSleep(uint64_t secs) {
    DPRINTF("[Sleep] Light sleep %llu s\n", secs);
    digitalWrite(PIN_LED_STATUS, LOW);
    esp_sleep_enable_timer_wakeup(secs * 1000000ULL);
    esp_light_sleep_start();
    DPRINTLN(F("[Sleep] Despertando"));
    markActivity();
  }
  void setLED(bool on) { digitalWrite(PIN_LED_STATUS, on); }
  void blink(int n, int ms = 200) {
    for (int i = 0; i < n; i++) {
      digitalWrite(PIN_LED_STATUS, HIGH); delay(ms);
      digitalWrite(PIN_LED_STATUS, LOW);  delay(ms);
    }
  }
};

// ============================================================
// OBJETOS GLOBALES
// ============================================================
TFT_eSPI tft;
WifiManager    wifi;
TimeSync       timeSync;
CalendarFetcher calendar;
ScreenRenderer screen(tft);
PowerManager   power;

// ============================================================
// MAQUINA DE ESTADOS
// ============================================================
enum State { ST_BOOT, ST_WIFI, ST_NTP, ST_FETCH, ST_RENDER, ST_IDLE, ST_ERROR, ST_SLEEP };
State currentState = ST_BOOT;
unsigned long stateStart = 0, lastFetch = 0, lastRender = 0, lastViewCycle = 0;
int errorCount = 0;

void changeState(State s) {
  DPRINTF("[State] %d -> %d\n", currentState, s);
  currentState = s; stateStart = millis();
}

void handleBoot() {
  DPRINTLN(F("\n=== CALENDARIO FAMILIAR v1.0 ==="));
  Serial.begin(115200); delay(500);
  power.begin(); screen.begin(); power.setLED(true);
  screen.showSplash("Iniciando...");
  changeState(ST_WIFI);
}

void handleWifi() {
  screen.showSplash("Conectando WiFi...");
  if (wifi.connect()) { power.blink(2); changeState(ST_NTP); }
  else { screen.showError("WiFi Error", "No se pudo conectar.\nVerifique config.h"); power.blink(5, 100); changeState(ST_ERROR); }
}

void handleNtp() {
  screen.showSplash("Sincronizando hora...");
  if (timeSync.sync()) { power.blink(1, 500); changeState(ST_FETCH); }
  else { screen.showError("NTP Error", "No se pudo sincronizar\nla hora."); changeState(ST_ERROR); }
}

void handleFetch() {
  screen.showSplash("Descargando eventos...");
  if (calendar.fetch(wifi)) { errorCount = 0; lastFetch = millis(); changeState(ST_RENDER); }
  else {
    errorCount++;
    DPRINTF("[Fetch] Fallo #%d: %s\n", errorCount, calendar.getLastError());
    if (errorCount >= 3) {
      screen.showError("Error red", "Multiples fallos.\nReintentando en 5 min...");
      delay(3000); changeState(ST_SLEEP);
    } else {
      screen.showError("Error temp", "Fallo al descargar.\nReintentando...");
      delay(5000); changeState(ST_WIFI);
    }
  }
}

void handleRender() {
  power.markActivity();
  char sb[64];
  struct tm now;
  if (timeSync.getNow(&now)) {
    char tb[10], db[12];
    timeSync.fmtTime(tb, sizeof(tb), &now);
    timeSync.fmtDate(db, sizeof(db), &now);
    snprintf(sb, 64, "Actualizado %s %s", db, tb);
  } else snprintf(sb, 64, "Actualizado");
  int rssi = wifi.isConnected() ? wifi.getRSSI() : 0;
  screen.render(calendar, timeSync, rssi, sb);
  lastRender = millis();
  changeState(ST_IDLE);
}

void handleIdle() {
  wifi.maintain();
  timeSync.maintain();
  // Auto-ciclar vistas cada VIEW_CYCLE_SEC
  if (millis() - lastViewCycle >= VIEW_CYCLE_SEC * 1000UL) {
    lastViewCycle = millis();
    int nv = screen.getCurrentView() + 1; if (nv > 1) nv = 0;
    screen.setView(nv); changeState(ST_RENDER); return;
  }
  if (millis() - lastFetch >= CALENDAR_UPDATE_INTERVAL_SEC * 1000UL) {
    changeState(ST_FETCH); return;
  }
  power.checkIdle();
  if (ENABLE_SLEEP && (millis() - lastRender) > (BACKLIGHT_TIMEOUT_SEC + 60) * 1000UL) {
    changeState(ST_SLEEP); return;
  }
  delay(100);
}

void handleError() {
  power.setLED(millis() % 1000 < 500);
  if (millis() - stateStart > 30000) { changeState(ST_BOOT); return; }
  delay(100);
}

void handleSleep() {
  power.lightSleep(SLEEP_DURATION_SEC);
  changeState(ST_BOOT);
}

// ============================================================
// SETUP & LOOP
// ============================================================
void setup() {
  currentState = ST_BOOT; stateStart = millis();
}

void loop() {
  switch (currentState) {
    case ST_BOOT:   handleBoot();   break;
    case ST_WIFI:   handleWifi();   break;
    case ST_NTP:    handleNtp();    break;
    case ST_FETCH:  handleFetch();  break;
    case ST_RENDER: handleRender(); break;
    case ST_IDLE:   handleIdle();   break;
    case ST_ERROR:  handleError();  break;
    case ST_SLEEP:  handleSleep();  break;
  }
}
