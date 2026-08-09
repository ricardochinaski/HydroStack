import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wokwi_service.dart';
import '../services/rtdb_service.dart';
import '../providers/settings_provider.dart';
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

/// Stream de telemetría activa. La fuente se auto-gestiona aquí:
/// - usarHardware = true  → Firebase RTDB del dispositivo vinculado
///                          (detiene el simulador local si estaba corriendo)
/// - usarHardware = false → Simulador local, arrancado automáticamente
/// Todos los providers/widgets que consumen este stream no necesitan cambios.
final wokwiLecturaProvider = StreamProvider<LecturaSensor>((ref) {
  final usarHardware = ref.watch(settingsProvider.select((s) => s.usarHardware));
  final sim = ref.watch(wokwiServiceProvider);

  if (usarHardware) {
    if (sim.isSimulating) sim.stopSimulation();
    final deviceId = ref.watch(settingsProvider.select((s) => s.deviceId));
    return ref.watch(rtdbServiceProvider).streamFor(deviceId);
  }

  // Fuente simulador: arranca solo si no hay conexión activa (WS o sim).
  if (!sim.isConnected) sim.startSimulation();
  return sim.stream;
});

/// Punto único para enviar comandos, sin importar la fuente activa:
/// - usarHardware = true  → escribe en Firebase RTDB (el gateway lo reenvía
///                          por UART al controlador local real)
/// - usarHardware = false → actúa sobre el estado interno del simulador
/// Toda la UI (botones de riego, luz, nutrientes, etc.) debe llamar esta
/// función en vez de invocar wokwiServiceProvider o rtdbServiceProvider
/// directamente, para funcionar igual en ambos modos.
Future<void> enviarComando(WidgetRef ref, String cmd, String value) async {
  final usarHardware = ref.read(settingsProvider).usarHardware;
  if (usarHardware) {
    final deviceId = ref.read(settingsProvider).deviceId;
    await ref.read(rtdbServiceProvider).enviarComando(deviceId, cmd, value);
  } else {
    await ref.read(wokwiServiceProvider).sendCommand(cmd, value);
  }
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
