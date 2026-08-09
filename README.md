# HydroStack

HydroStack es un sistema en desarrollo para supervisar y controlar una huerta hidropónica vertical. El repositorio reúne una aplicación Flutter, firmware para tres nodos de hardware, integración con Firebase, simulaciones y material histórico de las etapas HidroSmart, HuertaViva y HuertaApp.

## Estado actual

El proyecto está en fase de prototipo. La aplicación puede trabajar con Firebase cuando su configuración local está disponible y, en caso contrario, utiliza implementaciones mock y una simulación local. El onboarding de conexión del dispositivo y algunas funciones de datos o diagnóstico siguen siendo simulados. Los firmwares activos conservan credenciales placeholder y requieren configuración local antes de compilarse para hardware real.

## Arquitectura de alto nivel

- La aplicación Flutter gestiona autenticación, perfil, configuración de huerta, cosechas, telemetría y comandos.
- Firebase Auth proporciona acceso por correo/contraseña y Google cuando Firebase inicia correctamente.
- Cloud Firestore almacena datos de usuario, configuración de huerta y cosechas; parte del catálogo, alertas y lecturas semilla aún usa datos mock.
- Firebase Realtime Database conecta la aplicación con el gateway ESP8266 mediante rutas por identificador de dispositivo.
- El Arduino Mega 2560 concentra sensores, pantalla y relés, y se comunica por UART con el ESP8266.
- El ESP8266 aporta WiFi, publica telemetría en RTDB y reenvía comandos al Mega.
- El ESP32-CAM funciona como nodo independiente: ofrece streaming en la red local y contempla subir capturas a Firebase Storage y estado a RTDB.
- Wokwi conserva una simulación ESP32 separada del firmware físico activo. La app también contiene un simulador local escrito en Dart.

La descripción detallada está en [docs/architecture.md](docs/architecture.md).

## Estructura del repositorio

```text
apps/mobile/                 Aplicación Flutter activa
firmware/controller-mega/    Firmware activo del Arduino Mega 2560
firmware/gateway-esp8266/    Firmware activo del gateway ESP8266
firmware/camera-esp32cam/    Firmware activo del nodo ESP32-CAM
simulations/wokwi/           Proyecto de simulación Wokwi
firebase/                    Índice de la integración Firebase versionada
hardware/                    Índice de hardware y fuentes verificables
assets/plants/               Recursos gráficos generales de plantas
assets/parameters/           Recursos gráficos generales de parámetros
docs/                        Documentación técnica vigente
docs/legacy/                 Prototipos, reportes, simulaciones y firmware históricos
```

Los assets que compila Flutter permanecen en `apps/mobile/assets/` y están declarados en `apps/mobile/pubspec.yaml`.

## Componentes

### Aplicación Flutter

La aplicación activa se encuentra en `apps/mobile/`. Conserva sus nombres internos históricos, package name, `applicationId`, namespace, rutas, Riverpod, GoRouter y configuración Firebase. Para trabajar con ella:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Firmware

Cada nodo activo tiene una carpeta propia bajo `firmware/`. Los archivos históricos no se eliminaron: están documentados y preservados bajo `docs/legacy/`.

### Firebase

La integración actual y sus rutas se describen en [docs/firebase.md](docs/firebase.md). Los archivos locales de configuración como `google-services.json` y `GoogleService-Info.plist` no se versionan.

### Simulación

`simulations/wokwi/` contiene el proyecto Wokwi confirmado. La simulación local que alimenta la interfaz vive en `apps/mobile/lib/services/wokwi_service.dart`; no depende de abrir el proyecto Wokwi.

## Documentación

- [Arquitectura](docs/architecture.md)
- [Hardware](docs/hardware.md)
- [Firebase](docs/firebase.md)
- [Asociación y provisioning](docs/device-provisioning.md)
- [Material histórico](docs/legacy/README.md)

HydroStack todavía no debe considerarse un producto terminado ni una instalación lista para producción.
