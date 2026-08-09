#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>

// Configuración de pines para el modelo clásico ESP32-CAM AI-Thinker
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

// Tus credenciales de red
const char* ssid = "TU_WIFI_SSID";
const char* password = "TU_WIFI_PASSWORD";

WebServer server(80);

// Cabeceras para el streaming de video continuo (MJPEG)
const char HEADER[] = "HTTP/1.1 200 OK\r\n" \
                      "Access-Control-Allow-Origin: *\r\n" \
                      "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n";
const char BOUNDARY[] = "\r\n--frame\r\n";
const char CTNTTYPE[] = "Content-Type: image/jpeg\r\nContent-Length: ";

void handle_jpg_stream(void) {
  WiFiClient client = server.client();
  if (!client.connected()) return;

  client.print(HEADER);
  
  while (client.connected()) {
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Fallo al capturar el frame de la cámara");
      delay(100);
      continue;
    }

    client.print(BOUNDARY);
    client.print(CTNTTYPE);
    client.print(fb->len);
    client.print("\r\n\r\n");
    
    uint8_t *out_buf = fb->buf;
    size_t out_len = fb->len;
    client.write(out_buf, out_len);
    
    esp_camera_fb_return(fb);
    
    // Un pequeño delay para estabilizar los frames por segundo (FPS)
    delay(40);
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println();
  
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  
  // Ajuste de resolución y calidad según disponibilidad de PSRAM
  if(psramFound()){
    config.frame_size = FRAMESIZE_VGA; // Resolución idónea para smartphones (640x480)
    config.jpeg_quality = 12;          // Rango de 0 a 63 (menor número es mayor calidad)
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  // Inicializar la cámara
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Error al inicializar la cámara: 0x%x", err);
    return;
  }

  // Conexión Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Conectando a la red Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\n¡Wi-Fi Conectado exitosamente!");
  Serial.print("Dirección IP asignada: ");
  Serial.println(WiFi.localIP());

  // Configurar la ruta raíz del servidor para el streaming
  server.on("/", handle_jpg_stream);
  server.begin();
}

void loop() {
  server.handleClient();
}
