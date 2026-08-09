import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alerta.dart';
import '../services/firestore_service.dart';

final alertasProvider = StateNotifierProvider<AlertasNotifier, AsyncValue<List<Alerta>>>((ref) {
  return AlertasNotifier(ref.read(firestoreServiceProvider));
});

class AlertasNotifier extends StateNotifier<AsyncValue<List<Alerta>>> {
  final FirestoreService _firestoreService;

  AlertasNotifier(this._firestoreService) : super(const AsyncValue.data([]));

  Future<void> loadAlertas() async {
    state = const AsyncValue.loading();
    try {
      final alertas = await _firestoreService.getAlertas('mock-huerta-001');
      state = AsyncValue.data(alertas);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Agrega una alerta dinámica (de la telemetría). Si ya existe una alerta
  /// SIN resolver con el mismo id, no la duplica.
  void addAlerta(Alerta alerta) {
    final current = state.valueOrNull ?? [];
    final yaExiste = current.any((a) => a.id == alerta.id && !a.resuelta);
    if (yaExiste) return;
    // reemplaza una versión resuelta anterior del mismo id, si la hay
    final sinViejas = current.where((a) => a.id != alerta.id).toList();
    state = AsyncValue.data([alerta, ...sinViejas]);
  }

  Future<void> marcarResuelta(String alertaId) async {
    await _firestoreService.marcarAlertaResuelta(alertaId);
    final current = state.valueOrNull ?? [];
    final updated = current.map((a) {
      return a.id == alertaId ? a.copyWith(resuelta: true) : a;
    }).toList();
    state = AsyncValue.data(updated);
  }

  int get pendientesCount {
    return state.valueOrNull?.where((a) => !a.resuelta).length ?? 0;
  }
}
