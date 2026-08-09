import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alerta.dart';
import '../models/user.dart';
import '../services/wokwi_service.dart';
import '../services/notification_service.dart';
import 'wokwi_provider.dart';
import 'user_provider.dart';
import 'alertas_provider.dart';
import 'notif_prefs_provider.dart';

/// Regla de notificación: condición sobre la telemetría → alerta.
class _Regla {
  final String id;
  final String icon;
  final String titulo;
  final Prioridad prioridad;
  final bool Function(LecturaSensor t) condicion;
  final String Function(LecturaSensor t) descripcion;
  final bool seguridad; // ignora horario silencioso
  final bool Function(NotifPrefs p) habilitada;
  final bool soloConSensores; // requiere modelo Eco/Pro

  const _Regla({
    required this.id,
    required this.icon,
    required this.titulo,
    required this.prioridad,
    required this.condicion,
    required this.descripcion,
    required this.habilitada,
    this.seguridad = false,
  }) : soloConSensores = true;
}

final _reglas = <_Regla>[
  _Regla(
    id: 'agua_baja',
    icon: '💧',
    titulo: 'Agua baja',
    prioridad: Prioridad.urgente,
    seguridad: true,
    condicion: (t) => t.nivelAgua < 25,
    descripcion: (t) => 'El reservorio está al ${t.nivelAgua.toStringAsFixed(0)}%. Agrega agua pronto.',
    habilitada: (p) => p.aguaBaja,
  ),
  _Regla(
    id: 'ph_rango',
    icon: '⚗️',
    titulo: 'pH fuera de rango',
    prioridad: Prioridad.atencion,
    condicion: (t) => t.ph < 5.2 || t.ph > 6.8,
    descripcion: (t) => 'El pH está en ${t.ph.toStringAsFixed(1)} (ideal 5.5–6.5).',
    habilitada: (p) => p.alertasPH,
  ),
  _Regla(
    id: 'temp_extrema',
    icon: '🌡️',
    titulo: 'Temperatura extrema',
    prioridad: Prioridad.atencion,
    condicion: (t) => t.tempAmbiente > 30 || t.tempAmbiente < 12,
    descripcion: (t) => 'Temperatura ambiente de ${t.tempAmbiente.toStringAsFixed(0)}°C.',
    habilitada: (p) => p.temperatura,
  ),
];

class _Engine {
  final Ref _ref;
  final Map<String, DateTime> _ultimaVez = {};
  // En demo, no repetir la misma alerta antes de 45 s.
  static const _cooldown = Duration(seconds: 45);

  _Engine(this._ref);

  void onTelemetry(LecturaSensor t) {
    final modo = _ref.read(userModeProvider);
    if (modo == AppMode.basic) return; // sin sensores → sin alertas de telemetría

    final prefs = _ref.read(notifPrefsProvider);
    final ahora = DateTime.now();

    for (final regla in _reglas) {
      if (!regla.habilitada(prefs)) continue;
      if (!regla.condicion(t)) continue;

      final ultima = _ultimaVez[regla.id];
      if (ultima != null && ahora.difference(ultima) < _cooldown) continue;
      _ultimaVez[regla.id] = ahora;

      // Alerta en la app (siempre, alimenta la campana y el centro de alertas)
      _ref.read(alertasProvider.notifier).addAlerta(Alerta(
        id: regla.id,
        icon: regla.icon,
        titulo: regla.titulo,
        descripcion: regla.descripcion(t),
        prioridad: regla.prioridad,
        fecha: ahora,
      ));

      // Notificación del sistema (respeta horario silencioso salvo seguridad)
      final silenciar = prefs.enHorarioSilencioso && !regla.seguridad;
      if (!silenciar) {
        _ref.read(notificationServiceProvider).showLocalNotification(
          title: regla.titulo,
          body: regla.descripcion(t),
        );
      }
    }
  }
}

/// Motor de notificaciones. Se mantiene vivo mientras alguien lo observe
/// (lo observa HomeScreen). Escucha la telemetría y genera alertas/avisos.
final notificationEngineProvider = Provider<void>((ref) {
  final engine = _Engine(ref);
  ref.listen<AsyncValue<LecturaSensor>>(wokwiLecturaProvider, (prev, next) {
    next.whenData(engine.onTelemetry);
  });
});
