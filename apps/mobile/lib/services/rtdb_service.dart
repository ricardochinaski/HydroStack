import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_command.dart';
import 'firebase_init.dart';
import 'wokwi_service.dart';

/// Acceso RTDB para telemetría y comandos del hardware real.
///
/// Contrato de comandos v2:
///   /dispositivos/{deviceId}/comandos/{actuator}/{commandId}
///     commandId   String único e inmutable
///     value       bool
///     issuedAt    timestamp RTDB generado por servidor (ms)
///     ttlMs       vida máxima del comando
///     requestedBy UID autenticado
///
///   /dispositivos/{deviceId}/commandPointers/{actuator} = commandId
///
/// El registro del comando es inmutable. Primero se crea la orden y solo si esa
/// escritura tiene éxito se avanza el puntero. Un fallo en el segundo paso puede
/// dejar un registro huérfano, pero nunca ejecutar un comando incompleto.
///
/// El gateway publica la confirmación del controlador local en:
///   /dispositivos/{deviceId}/commandAcks/{actuator}/{commandId}
///     commandId, status, code, at
class RTDBService {
  RTDBService._();
  static final RTDBService instance = RTDBService._();

  static const int commandTtlMs = 10000;

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
            tempAmbiente:
                _num(raw['temp_aire'] ?? raw['temperatura']) ?? 24.0,
            humedadAmbiente: _num(raw['humedad']) ?? 60.0,
            tempAgua: _num(raw['temp_agua']) ?? 20.0,
            nivelAgua: _num(raw['nivel_agua']) ?? 0.0,
            mode: 'eco',
            relays: [
              _bool(raw['relay_nutrientes']) ? 1 : 0,
              0,
              _bool(raw['relay_luz']) ? 1 : 0,
              _bool(raw['relay_bomba']) ? 1 : 0,
              _bool(raw['relay_auxiliar']) ? 1 : 0,
            ],
            heartbeat: raw['timestamp']?.toString() ?? '',
          );
        });
  }

  /// Crea una orden v2 inmutable y devuelve el [commandId] que correlaciona el
  /// ACK. El puntero solo se mueve después de que el registro quedó persistido.
  Future<String?> enviarComando(
    String deviceId,
    String cmd,
    String value,
  ) async {
    if (!firebaseReady || deviceId.isEmpty) return null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;

    final normalized = _normalizeCommand(cmd, value);
    if (normalized == null) return null;

    final root = FirebaseDatabase.instance.ref();
    final commandId = root.push().key;
    if (commandId == null || commandId.isEmpty) return null;

    final base = 'dispositivos/$deviceId';
    final commandRef = root.child(
      '$base/comandos/${normalized.actuator}/$commandId',
    );
    final pointerRef = root.child(
      '$base/commandPointers/${normalized.actuator}',
    );

    await commandRef.set({
      'commandId': commandId,
      'value': normalized.value,
      'issuedAt': ServerValue.timestamp,
      'ttlMs': commandTtlMs,
      'requestedBy': uid,
    });

    await pointerRef.set(commandId);
    return commandId;
  }

  Stream<DeviceCommandAck> ackStreamFor(
    String deviceId,
    String actuator,
    String commandId,
  ) {
    if (!firebaseReady ||
        deviceId.isEmpty ||
        commandId.isEmpty ||
        !_validActuator(actuator)) {
      return const Stream.empty();
    }

    return FirebaseDatabase.instance
        .ref('dispositivos/$deviceId/commandAcks/$actuator/$commandId')
        .onValue
        .where((event) => event.snapshot.value is Map)
        .map((event) {
          final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
          return DeviceCommandAck.fromMap(actuator, raw);
        });
  }

  _NormalizedCommand? _normalizeCommand(String cmd, String value) {
    final boolValue = value == '1' || value == 'true';
    switch (cmd) {
      case 'luz':
        return _NormalizedCommand('luz', boolValue);
      case 'auxiliar':
        return _NormalizedCommand('auxiliar', boolValue);
      case 'bomba':
        return const _NormalizedCommand('bomba', true);
      case 'regar':
        return const _NormalizedCommand('nutrientes', true);
      default:
        return null;
    }
  }

  bool _validActuator(String actuator) =>
      actuator == 'luz' ||
      actuator == 'auxiliar' ||
      actuator == 'bomba' ||
      actuator == 'nutrientes';

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

class _NormalizedCommand {
  final String actuator;
  final bool value;

  const _NormalizedCommand(this.actuator, this.value);
}
