/*
 * HidroSmart — Firmware de Simulación para Wokwi
 * SIN dependencias externas (JSON manual)
 * 
 * GPIO 34: Sensor pH (potenciómetro, entrada analógica)
 * GPIO 35: Sensor EC (potenciómetro, entrada analógica)
 * GPIO 25: Relé 1 — Bomba de Nutrientes Peristáltica
 * GPIO 26: Relé 2 — Bomba Corrector pH / Riego
 * GPIO 27: Relé 3 — Sistema Iluminación LED
 * 
 * Protocolo Serial (JSON):
 *   RX: {"cmd":"modo","value":"eco"}
 *       {"cmd":"rele","pin":25,"state":1}
 *   TX: {"ph":7.0,"ec":1.8,"mode":"eco","relays":[0,0,0],"heartbeat":"alive"}
 */

#include <stdio.h>

// Pines
const int PIN_PH = 34;
const int PIN_EC = 35;
const int RELE[] = {25, 26, 27};

// Estado
String currentMode = "eco";
bool relayState[3] = {false, false, false};
unsigned long lastPublish = 0;
const unsigned long PUBLISH_INTERVAL = 1000;

char buffer[256];

float adcToPH(int raw) {
  return 4.0 + (raw / 4095.0) * 6.0;
}

float adcToEC(int raw) {
  return 0.2 + (raw / 4095.0) * 4.0;
}

void setRelays() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(RELE[i], relayState[i] ? HIGH : LOW);
  }
}

void publishTelemetry(float ph, float ec) {
  sprintf(buffer,
    "{\"ph\":%.2f,\"ec\":%.2f,\"mode\":\"%s\",\"relays\":[%d,%d,%d],\"heartbeat\":\"alive\"}",
    ph, ec, currentMode.c_str(),
    relayState[0] ? 1 : 0,
    relayState[1] ? 1 : 0,
    relayState[2] ? 1 : 0
  );
  Serial.println(buffer);
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_PH, INPUT);
  pinMode(PIN_EC, INPUT);
  for (int i = 0; i < 3; i++) pinMode(RELE[i], OUTPUT);
  setRelays();
  Serial.println("{\"msg\":\"HidroSmart ESP32 iniciado\"}");
}

void loop() {
  int rawPH = analogRead(PIN_PH);
  int rawEC = analogRead(PIN_EC);
  float ph = adcToPH(rawPH);
  float ec = adcToEC(rawEC);

  unsigned long now = millis();
  if (now - lastPublish >= PUBLISH_INTERVAL) {
    lastPublish = now;
    publishTelemetry(ph, ec);
  }

  if (Serial.available()) {
    String input = Serial.readStringUntil('\n');
    input.trim();

    // Parsear comando JSON manualmente
    if (input.indexOf("\"cmd\":\"modo\"") >= 0) {
      int vStart = input.indexOf("\"value\":\"") + 9;
      int vEnd = input.indexOf("\"", vStart);
      String mode = input.substring(vStart, vEnd);
      currentMode = mode;

      if (currentMode == "eco") {
        relayState[0] = true;  relayState[1] = false; relayState[2] = false;
      } else if (currentMode == "autonomo") {
        relayState[0] = true;  relayState[1] = true;  relayState[2] = false;
      } else if (currentMode == "pro") {
        relayState[0] = true;  relayState[1] = true;  relayState[2] = true;
      }
      setRelays();
      sprintf(buffer, "{\"ack\":\"modo\",\"mode\":\"%s\"}", currentMode.c_str());
      Serial.println(buffer);

    } else if (input.indexOf("\"cmd\":\"rele\"") >= 0) {
      int pStart = input.indexOf("\"pin\":") + 6;
      int pEnd = input.indexOf(",", pStart);
      int pin = input.substring(pStart, pEnd).toInt();
      int sStart = input.indexOf("\"state\":") + 8;
      int sEnd = input.indexOf("}", sStart);
      int state = input.substring(sStart, sEnd).toInt();
      int idx = pin - 25;
      if (idx >= 0 && idx < 3) {
        relayState[idx] = (state == 1);
        digitalWrite(pin, relayState[idx] ? HIGH : LOW);
        sprintf(buffer, "{\"ack\":\"rele\",\"pin\":%d,\"state\":%d}", pin, state);
        Serial.println(buffer);
      }
    }
  }

  delay(50);
}
