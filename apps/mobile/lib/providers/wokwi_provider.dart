import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wokwi_service.dart';
import '../services/rtdb_service.dart';
import 'device_provider.dart';
import 'settings_provider.dart';
import '../models/lectura_sensor.dart' as model;
import '../models/user.dart';

final wokwiServiceProvider = Provider<WokwiService>((ref) {
  final service = WokwiService();
  ref.onDispose(() => service.dispose());
  return service;
});

final wokwiConnectionProvider = StateProvider<bool>((ref) => false);

final rtdbServiceProvider = Provider<RTDBService>((ref) => RTDBService.instance);

/// Momento en que llegó la última lectura (para detectar pérdida de señal).
final ultimaLecturaProvider = StateProvider<DateTime?>((ref) => null);

/// Stream de telemetría activa.
///
/// Producción: el ID preferido local nunca basta por sí solo. Se usa únicamente
/// el dispositivo que [authorizedDeviceProvider] verificó contra
/// `devices/{deviceId}.ownerUid` en Firestore.
///
/// Desarrollo: un ID manual se permite solo cuando el usuario habilitó de forma
/// explícita `useDevelopmentDevice`. Ese modo no representa ownership real.
final wokwiLecturaProvider = StreamProvider<LecturaSensor>((ref) {
  final settings = ref.watch(settingsProvider);
  final sim = ref.watch(wokwiServiceProvider);

  if (settings.usarHardware) {
    if (sim.isSimulating) sim.stopSimulation();

    if (settings.useDevelopmentDevice) {
      return ref.watch(rtdbServiceProvider).streamFor(
            settings.developmentDeviceId,
          );
    }

    final authorized = ref.watch(authorizedDeviceProvider).valueOrNull;
    if (authorized == null) return const Stream.empty();
    return ref.watch(rtdbServiceProvider).streamFor(authorized.deviceId);
  }

  if (!sim.isConnected) sim.startSimulation();
  return sim.stream;
});

/// Punto único para enviar comandos, sin importar la fuente activa.
///
/// En hardware real de producción, el comando solo se envía si Firestore
/// confirma que el usuario autenticado es owner del dispositivo seleccionado.
Future<void> enviarComando(WidgetRef ref, String cmd, String value) async {
  final settings = ref.read(settingsProvider);
  if (settings.usarHardware) {
    if (settings.useDevelopmentDevice) {
      await ref.read(rtdbServiceProvider).enviarComando(
            settings.developmentDeviceId,
            cmd,
            value,
          );
      return;
    }

    final authorized = await ref.read(authorizedDeviceProvider.future);
    if (authorized == null) return;
    await ref.read(rtdbServiceProvider).enviarComando(
          authorized.deviceId,
          cmd,
          value,
        );
    return;
  }

  await ref.read(wokwiServiceProvider).sendCommand(cmd, value);
}

/// Convierte la telemetría cruda en la lista de sensores que la app muestra,
/// respetando el modelo de hardware:
/// - Basic: sin sensores.
/// - Eco: pH, temperatura (aire/agua), humedad y nivel. Sin EC.
/// - Pro: todos los anteriores + EC de nutrientes.
List<model.LecturaSensor> sensoresDesdeTelemetria(LecturaSensor t, AppMode modo) {
  if (modo == AppMode.basic) return const [];
  final now = DateTime.now();

  final list = <model.LecturaSensor>[
    model.LecturaSensor(
      id: 'ph', sensorName: 'pH agua', icon: '', unidad: '',
      valor: t.ph, minOptimo: 5.5, maxOptimo: 6.5, timestamp: now, rango: '5.5 – 6.5',
    ),
  ];

  if (modo == AppMode.pro) {
    list.add(model.LecturaSensor(
      id: 'ec', sensorName: 'EC nutrientes', icon: '', unidad: 'mS/cm',
      valor: t.ec, minOptimo: 1.6, maxOptimo: 2.0, timestamp: now, rango: '1.6 – 2.0 mS/cm',
    ));
  }

  list.addAll([
    model.LecturaSensor(
      id: 'tagua', sensorName: 'Temperatura agua', icon: '', unidad: '°C',
      valor: t.tempAgua, minOptimo: 18, maxOptimo: 22, timestamp: now, rango: '18 – 22 °C',
    ),
    model.LecturaSensor(
      id: 'tamb', sensorName: 'Temperatura ambiente', icon: '', unidad: '°C',
      valor: t.tempAmbiente, minOptimo: 22, maxOptimo: 28, timestamp: now, rango: '22 – 28 °C',
    ),
    model.LecturaSensor(
      id: 'hum', sensorName: 'Humedad ambiente', icon: '', unidad: '%',
      valor: t.humedadAmbiente, minOptimo: 55, maxOptimo: 70, timestamp: now, rango: '55 – 70 %',
    ),
    model.LecturaSensor(
      id: 'nivel', sensorName: 'Nivel agua', icon: '', unidad: '%',
      valor: t.nivelAgua, minOptimo: 30, maxOptimo: 100, timestamp: now, rango: 'mín. 30 %',
    ),
  ]);

  return list;
}
