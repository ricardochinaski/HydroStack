/**
 * HidroSmart — ESP32-CAM (AI-Thinker)
 * Nodo de cámara independiente: NO se conecta al Mega ni al ESP8266,
 * tiene su propia conexión WiFi y se identifica con el mismo DEVICE_ID
 * para que la app lo asocie a la misma torre en Firebase.
 *
 * Funciones:
 *  1. Servidor de streaming MJPEG en el puerto 81 (para ver la torre en
 *     vivo desde el navegador mientras estés en la misma red WiFi).
 *  2. Página HTML simple en el puerto 80 con el stream embebido, para
 *     abrir directamente desde el celular sin la app.
 *  3. Captura una foto cada INTERVALO_FOTO horas y la sube a Firebase
 *     Storage (timelapse de crecimiento).
 *
 * Esquema Firebase:
 *  /dispositivos/{DEVICE_ID}/camara/
 *    - streamUrl        "http://<ip-local>:81/stream"  (solo accesible en la misma red)
 *    - ip               IP local actual
 *    - ultimaFotoUrl    URL pública de la última foto en Storage
 *    - ultimaFotoTs     Timestamp ISO8601 de la última foto
 *
 * ⚠️ ANTES DE COMPILAR:
 *  1. Completa WIFI_SSID / WIFI_PASSWORD / FIREBASE_* más abajo.
 *  2. Reemplaza STORAGE_BUCKET_ID por el bucket real de tu proyecto
 *     (Firebase Console → Storage → el nombre que aparece arriba,
 *     normalmente "hidrosmart-81f2b.appspot.com" o
 *     "hidrosmart-81f2b.firebasestorage.app" según la fecha de creación
 *     del proyecto — verifícalo, no lo asumas).
 *  3. Programar: usa el NodeMCU como adaptador USB-serial (puente EN→GND
 *     en el NodeMCU, GPIO0→GND en la CAM durante la subida) o un FTDI/
 *     la placa base ESP32-CAM-MB si la tienes.
 *
 * Librerías (Board Manager: esp32 by Espressif — incluye esp_camera.h):
 *  · Firebase ESP Client (Mobizt) — la librería UNIFICADA para ESP8266+ESP32.
 *    Ojo: NO es la misma que "Firebase ESP8266 Client" (usada en el gateway)
 *    ni que la antigua "Firebase ESP32 Client" — instala literalmente
 *    "Firebase ESP Client" desde el Library Manager (API con namespaces
 *    Firebase.RTDB.* y Firebase.Storage.*, que es la que usa este archivo).
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ── CREDENCIALES ─────────────────────────────────────────────────
#define WIFI_SSID         "TU_WIFI_SSID"
#define WIFI_PASSWORD     "TU_WIFI_PASSWORD"
#define FIREBASE_HOST     "TU_FIREBASE_RTDB_HOST"
#define FIREBASE_AUTH     "TU_FIREBASE_LEGACY_TOKEN"
#define STORAGE_BUCKET_ID "TU_FIREBASE_STORAGE_BUCKET"   // verifica el tuyo

#define DEVICE_ID      "HS-001"
#define RUTA_CAMARA    "/dispositivos/" DEVICE_ID "/camara"

// ── PINES — AI-Thinker ESP32-CAM (fijos de fábrica) ──────────────
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22
#define FLASH_GPIO_NUM     4   // LED flash integrado

// ── OBJETOS FIREBASE ─────────────────────────────────────────────
FirebaseData   fbData;
FirebaseAuth   fbAuth;
FirebaseConfig fbConfig;

// ── SERVIDORES HTTP (streaming en 81, página índice en 80) ───────
WiFiServer servidorIndice(80);
WiFiServer servidorStream(81);

// ── TIMING ────────────────────────────────────────────────────────
const unsigned long INTERVALO_FOTO = 6UL * 60UL * 60UL * 1000UL; // 6 horas
unsigned long tUltimaFoto = 0;
bool primeraFotoHecha = false;

// =================================================================
void iniciarCamara();
void conectarWiFi();
void atenderIndice();
void atenderStream();
void capturarYSubirFoto();
void subirEstadoCamara(const String& fotoUrl);
void onUploadStatus(FCS_UploadStatusInfo info);

// =================================================================
void setup() {
  Serial.begin(115200);
  pinMode(FLASH_GPIO_NUM, OUTPUT);
  digitalWrite(FLASH_GPIO_NUM, LOW);

  iniciarCamara();
  conectarWiFi();

  fbConfig.host = FIREBASE_HOST;
  fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);

  servidorIndice.begin();
  servidorStream.begin();

  Serial.println();
  Serial.print(F("Streaming en:  http://"));
  Serial.print(WiFi.localIP());
  Serial.println(F(":81/stream"));
  Serial.print(F("Pagina simple: http://"));
  Serial.print(WiFi.localIP());
  Serial.println();

  // Toma la primera foto ~30s después de arrancar (deja que WiFi se asiente).
  tUltimaFoto = millis() - INTERVALO_FOTO + 30000UL;
}

// =================================================================
void loop() {
  atenderIndice();
  atenderStream();

  if (millis() - tUltimaFoto >= INTERVALO_FOTO) {
    tUltimaFoto = millis();
    capturarYSubirFoto();
  }
}

// =================================================================
void iniciarCamara() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // Con PSRAM (todas las ESP32-CAM la traen): más resolución y buffers.
  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA;   // 640×480, buen balance calidad/peso
    config.jpeg_quality = 12;            // menor = mejor calidad (rango 0-63)
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_CIF;
    config.jpeg_quality = 15;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Error inicializando la camara: 0x%x\n", err);
    delay(3000);
    ESP.restart();
  }
}

// =================================================================
void conectarWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < 15000UL) {
    delay(300);
  }
}

// =================================================================
// Página HTML mínima con el stream embebido (los navegadores renderizan
// multipart MJPEG dentro de una etiqueta <img> sin plugins).
void atenderIndice() {
  WiFiClient cliente = servidorIndice.available();
  if (!cliente) return;

  unsigned long t0 = millis();
  while (cliente.connected() && !cliente.available() && millis() - t0 < 1000) { delay(1); }
  while (cliente.available()) cliente.read(); // descarta el request, no lo necesitamos

  String ip = WiFi.localIP().toString();
  cliente.println("HTTP/1.1 200 OK");
  cliente.println("Content-Type: text/html");
  cliente.println("Connection: close");
  cliente.println();
  cliente.println("<!DOCTYPE html><html><head><title>HidroSmart Camara</title>");
  cliente.println("<meta name='viewport' content='width=device-width,initial-scale=1'>");
  cliente.println("<style>body{margin:0;background:#0D1117;display:flex;justify-content:center}img{max-width:100%;height:auto}</style>");
  cliente.println("</head><body>");
  cliente.print("<img src='http://"); cliente.print(ip); cliente.println(":81/stream'>");
  cliente.println("</body></html>");
  cliente.stop();
}

// =================================================================
// Streaming MJPEG: cada frame se envía como una parte multipart,
// separada por el boundary. El navegador (o VLC/Image.network con
// soporte multipart) lo reproduce como video.
void atenderStream() {
  WiFiClient cliente = servidorStream.available();
  if (!cliente) return;

  unsigned long t0 = millis();
  while (cliente.connected() && !cliente.available() && millis() - t0 < 1000) { delay(1); }
  while (cliente.available()) cliente.read();

  cliente.println("HTTP/1.1 200 OK");
  cliente.println("Content-Type: multipart/x-mixed-replace; boundary=frame");
  cliente.println();

  // Transmite mientras el cliente siga conectado (típicamente hasta que
  // cierre la pestaña del navegador). No bloquea el resto del sistema
  // porque solo hay un cliente de stream esperado a la vez (uso doméstico).
  while (cliente.connected()) {
    camera_fb_t* fb = esp_camera_fb_get();
    if (!fb) { delay(50); continue; }

    cliente.println("--frame");
    cliente.println("Content-Type: image/jpeg");
    cliente.print("Content-Length: "); cliente.println(fb->len);
    cliente.println();
    cliente.write(fb->buf, fb->len);
    cliente.println();

    esp_camera_fb_return(fb);

    if (!cliente.connected()) break;
    delay(50); // ~20 fps máx., suficiente para monitoreo de una huerta
  }
  cliente.stop();
}

// =================================================================
// Captura un frame y lo sube a Firebase Storage como JPEG.
void capturarYSubirFoto() {
  if (WiFi.status() != WL_CONNECTED) return;

  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println(F("[CAM] No se pudo capturar el frame"));
    return;
  }

  String remoto = "capturas/" + String(DEVICE_ID) + "_" + String(millis()) + ".jpg";

  Serial.print(F("[CAM] Subiendo foto (")); Serial.print(fb->len); Serial.println(F(" bytes)..."));

  bool ok = Firebase.Storage.upload(&fbData, STORAGE_BUCKET_ID, fb->buf, fb->len,
                                     remoto.c_str(), "image/jpeg", onUploadStatus);

  esp_camera_fb_return(fb);

  if (ok) {
    String url = "https://firebasestorage.googleapis.com/v0/b/" + String(STORAGE_BUCKET_ID) +
                 "/o/" + remoto + "?alt=media";
    // El nombre de archivo contiene '/', que Storage codifica como %2F en la URL pública.
    url.replace("capturas/", "capturas%2F");
    Serial.println(F("[CAM] Subida OK"));
    subirEstadoCamara(url);
  } else {
    Serial.print(F("[CAM] Error de subida: "));
    Serial.println(fbData.errorReason());
  }
}

// =================================================================
void onUploadStatus(FCS_UploadStatusInfo info) {
  if (info.status == firebase_fcs_upload_status_error) {
    Serial.print(F("[CAM] Error en callback de subida: "));
    Serial.println(info.errorMsg);
  }
}

// =================================================================
void subirEstadoCamara(const String& fotoUrl) {
  FirebaseJson json;
  json.set("ip",             WiFi.localIP().toString());
  json.set("streamUrl",      "http://" + WiFi.localIP().toString() + ":81/stream");
  json.set("ultimaFotoUrl",  fotoUrl);
  json.set("ultimaFotoTs",   (int)(millis() / 1000)); // referencia relativa simple

  Firebase.RTDB.setJSON(&fbData, RUTA_CAMARA, &json);
}
