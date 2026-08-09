# Material histórico

Esta carpeta conserva archivos de etapas anteriores. Su presencia no implica que describan la arquitectura activa.

## Prototipos

`prototypes/` contiene HTML de HuertaApp, HuertaViva e HidroSmart: flujos de app, base de plantas, electrónica, concepto técnico y páginas de presentación. Algunos enlaces ya eran rutas absolutas locales antes de la reorganización; el contenido se preservó sin reescribirlo.

## Reportes

`reports/` contiene la auditoría técnica HTML, el resumen PDF de la app y una lista de compras comparativa. Estos documentos mezclan estados y supuestos de distintas fechas, por lo que deben contrastarse con el código activo.

## Firmware histórico

`firmware/esp32cam-streaming-prototype/HidroSmart_Firmware.ino` estaba bajo una carpeta llamada `HidroSmart_Firmware`, pero su contenido incluye `esp_camera.h`, WiFi y un servidor MJPEG para ESP32-CAM. Es un prototipo de cámara más simple que el firmware activo, que además integra RTDB y Storage.

## Simulaciones históricas

`simulations/esp32-controller-v2/` conserva una simulación Python, un diagrama Wokwi y una lista de librerías de una arquitectura ESP32 anterior con pH, EC, OLED y tres relés. No coincide con el conjunto físico activo Mega + ESP8266.

## Firebase histórico

`firebase/FIREBASE_SETUP.md` es una guía anterior. Se archivó porque el package name que declara no coincide con el `applicationId` Android confirmado en el proyecto actual.

## Archivo ajeno a HydroStack

`unrelated/CalendarioFamiliar.ino` se conserva sin cambios. Su contenido implementa un calendario familiar y recordatorios; no usa sensores, actuadores, rutas Firebase ni protocolos de HydroStack. Por esa evidencia se clasificó como ajeno al proyecto.

## Sin clasificación segura

El archivo raíz vacío `nul` ya estaba versionado y no contiene información que permita determinar su origen. Se mantiene sin cambios para evitar una eliminación basada solo en su nombre.
