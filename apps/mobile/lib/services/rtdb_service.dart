import 'package:firebase_database/firebase_database.dart';
import 'firebase_init.dart';
import 'wokwi_service.dart';

/// Lee la telemetría del hardware real desde Firebase Realtime Database
/// y la convierte en el mismo tipo [LecturaSensor] que usa el simulador,
/// para que todos los providers/widgets funcionen sin cambios. También
/// permite escribir comandos hacia el dispositivo (control de relés).
///
/// Cada dispositivo físico escribe bajo su propio ID:
///   /dispositivos/{deviceId}/telemetria   ← el firmware escribe, la app lee
///   /dispositivos/{deviceId}/comandos     ← la app escribe, el firmware lee
/// El usuario vincula ese ID a su cuenta desde la app.
class RTDBService {
  RTDBService._();
  static final RTDBService instance = RTDBService._();

  /// Stream de telemetría del dispositivo [deviceId] (ej. "HS-001").
  Stream<LecturaSensor> streamFor(String deviceId) {
    if (!firebaseReady || deviceId.isEmpty) return const Stream.empty();

    return FirebaseDatabase.instance
        .ref('dispositivos/$deviceId/telemetria')
        .onValue
        .where((e) => e.snapshot.value != null)
        .map((e) {
          final raw = Map<String, dynamic>.from(e.snapshot.value as Map);

          return LecturaSensor(
            ph: _num(raw['ph'] ?? raw['pH']) ?? 7.0,
            ec: _num(raw['ec']) ?? 0.0,
            tempAmbiente: _num(raw['temp_aire'] ?? raw['temperatura']) ?? 24.0,
            humedadAmbiente: _num(raw['humedad']) ?? 60.0,
            tempAgua: _num(raw['temp_agua']) ?? 20.0,
            nivelAgua: _num(raw['nivel_agua']) ?? 0.0,
            mode: 'eco',
            // Mismo orden que el simulador: [nutrientes, pH-(sin actuador real), luz, bomba, auxiliar]
            relays: [
              _bool(raw['relay_nutrientes']) ? 1 : 0,
              0, // no existe bomba de pH- física en este hardware
              _bool(raw['relay_luz']) ? 1 : 0,
              _bool(raw['relay_bomba']) ? 1 : 0,
              _bool(raw['relay_auxiliar']) ? 1 : 0,
            ],
            heartbeat: raw['timestamp']?.toString() ?? '',
          );
        });
  }

  /// Envía un comando al dispositivo [deviceId] escribiendo en su nodo
  /// `comandos` de RTDB. El gateway (ESP8266) sondea este nodo y lo
  /// reenvía por UART al controlador local (Mega).
  ///
  /// Comandos soportados por el hardware real:
  /// - 'luz' / 'auxiliar': estado sostenido (toggle) — [valor] "1"=ON, "0"=OFF
  /// - 'bomba' / 'regar' (alias de nutrientes): disparo momentáneo — cualquier
  ///   valor no vacío dispara el pulso de 5s en el firmware
  ///
  /// Comandos sin actuador físico en este hardware ('ph', 'rellenar', 'modo')
  /// se ignoran silenciosamente: no hay bomba de pH- ni válvula de rellenado.
  Future<void> enviarComando(String deviceId, String cmd, String value) async {
    if (!firebaseReady || deviceId.isEmpty) return;
    final ref = FirebaseDatabase.instance.ref('dispositivos/$deviceId/comandos');

    switch (cmd) {
      case 'luz':
        await ref.child('luz').set(value == '1' || value == 'true');
        break;
      case 'auxiliar':
        await ref.child('auxiliar').set(value == '1' || value == 'true');
        break;
      case 'bomba':
        await ref.child('bomba').set(true);
        break;
      case 'regar': // alias existente en la UI para dosificación de nutrientes
        await ref.child('nutrientes').set(true);
        break;
      default:
        // 'ph', 'rellenar', 'modo': sin actuador físico en este hardware.
        break;
    }
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v.toString() == 'true';
  }
}
