import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

/// Preferencias de notificación del usuario (qué categorías recibir + horario
/// silencioso). Se persisten en shared_preferences.
class NotifPrefs {
  final bool aguaBaja; // siempre true (seguridad)
  final bool cosecha;
  final bool cambioAgua;
  final bool resumenDiario;
  final bool alertasPH;
  final bool temperatura;
  final bool horarioSilencioso;

  const NotifPrefs({
    this.aguaBaja = true,
    this.cosecha = true,
    this.cambioAgua = true,
    this.resumenDiario = false,
    this.alertasPH = false,
    this.temperatura = true,
    this.horarioSilencioso = false,
  });

  NotifPrefs copyWith({
    bool? cosecha,
    bool? cambioAgua,
    bool? resumenDiario,
    bool? alertasPH,
    bool? temperatura,
    bool? horarioSilencioso,
  }) {
    return NotifPrefs(
      aguaBaja: true,
      cosecha: cosecha ?? this.cosecha,
      cambioAgua: cambioAgua ?? this.cambioAgua,
      resumenDiario: resumenDiario ?? this.resumenDiario,
      alertasPH: alertasPH ?? this.alertasPH,
      temperatura: temperatura ?? this.temperatura,
      horarioSilencioso: horarioSilencioso ?? this.horarioSilencioso,
    );
  }

  /// ¿Estamos en horario silencioso (22:00–07:00) y está activado?
  bool get enHorarioSilencioso {
    if (!horarioSilencioso) return false;
    final h = DateTime.now().hour;
    return h >= 22 || h < 7;
  }
}

class NotifPrefsNotifier extends StateNotifier<NotifPrefs> {
  final dynamic _storage;
  NotifPrefsNotifier(this._storage) : super(const NotifPrefs()) {
    _load();
  }

  Future<void> _load() async {
    Future<bool> b(String k, bool def) async {
      final v = await _storage.getString('notif_$k');
      if (v == null) return def;
      return v == 'true';
    }

    state = NotifPrefs(
      cosecha: await b('cosecha', true),
      cambioAgua: await b('cambioAgua', true),
      resumenDiario: await b('resumenDiario', false),
      alertasPH: await b('alertasPH', false),
      temperatura: await b('temperatura', true),
      horarioSilencioso: await b('horarioSilencioso', false),
    );
  }

  Future<void> _save(String key, bool value) async {
    await _storage.setString('notif_$key', value.toString());
  }

  void setCosecha(bool v) { state = state.copyWith(cosecha: v); _save('cosecha', v); }
  void setCambioAgua(bool v) { state = state.copyWith(cambioAgua: v); _save('cambioAgua', v); }
  void setResumenDiario(bool v) { state = state.copyWith(resumenDiario: v); _save('resumenDiario', v); }
  void setAlertasPH(bool v) { state = state.copyWith(alertasPH: v); _save('alertasPH', v); }
  void setTemperatura(bool v) { state = state.copyWith(temperatura: v); _save('temperatura', v); }
  void setHorarioSilencioso(bool v) { state = state.copyWith(horarioSilencioso: v); _save('horarioSilencioso', v); }
}

final notifPrefsProvider = StateNotifierProvider<NotifPrefsNotifier, NotifPrefs>((ref) {
  return NotifPrefsNotifier(ref.read(storageServiceProvider));
});
