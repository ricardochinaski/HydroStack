# Configuración de Firebase — HidroSmart

El código de la app ya está integrado con Firebase (Auth con correo + Google, y
Cloud Firestore para los datos de usuario). Falta **solo la parte de la consola
y tu configuración**, que no se puede automatizar. Mientras no esté, la app
funciona en **modo mock** (datos locales).

> Package name del proyecto Android: **`cl.huertaviva.huerta_viva_app`**
> (debe coincidir exactamente en Firebase).

---

## 1. En la consola de Firebase (https://console.firebase.google.com)

Con tu proyecto ya creado:

1. **Authentication → Sign-in method**: habilita
   - **Correo electrónico/contraseña**
   - **Google**
2. **Firestore Database → Crear base de datos** (modo producción).
3. **Reglas de Firestore** (Firestore → Reglas) — cada usuario solo accede a lo suyo:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /usuarios/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
         match /{document=**} {
           allow read, write: if request.auth != null && request.auth.uid == uid;
         }
       }
     }
   }
   ```

---

## 2. Registrar la app Android y descargar google-services.json

1. En Firebase → **Configuración del proyecto → Tus apps → Agregar app → Android**.
2. **Nombre del paquete:** `cl.huertaviva.huerta_viva_app`
3. (Para Google Sign-In) agrega la **huella SHA-1** de tu keystore de debug:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copia el SHA-1 de la variante `debug` y pégalo en Firebase → tu app Android → "Agregar huella digital".
4. Descarga **`google-services.json`** y colócalo en:
   ```
   android/app/google-services.json
   ```

Eso es todo lo que la app necesita en Android: el Gradle ya está configurado
(plugin Google Services + minSdk 23).

---

## 3. Ejecutar en Android

```bash
flutter run            # con un emulador o dispositivo Android conectado
```

Al iniciar, la app detecta Firebase automáticamente (`firebaseReady = true`) y usa
Auth + Firestore reales. Crea una cuenta con correo o entra con Google: se creará
el documento `usuarios/{uid}` en Firestore con tu perfil y modelo.

---

## 4. (Opcional) Web

Para que Firebase funcione también en la versión web:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto genera `lib/firebase_options.dart`. Luego en `lib/main.dart` cambia
`Firebase.initializeApp()` por
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
(En Android no hace falta: se lee `google-services.json`.)

---

## Qué guarda en Firestore

- `usuarios/{uid}` → perfil (email, nombre, **modelo Basic/Eco/Pro**, fecha de creación).
- `usuarios/{uid}/huerta/config` → nombre, capacidad, plantas instaladas, estado ESP32.
- `usuarios/{uid}/cosechas/{id}` → registros de cosecha (planta, gramos, fecha, nota).

Si Firebase no está configurado, todo sigue funcionando con datos mock locales.
