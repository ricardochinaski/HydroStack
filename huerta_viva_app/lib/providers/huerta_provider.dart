import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/huerta.dart';
import '../models/lectura_sensor.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final huertaProvider = StateNotifierProvider<HuertaNotifier, AsyncValue<Huerta?>>((ref) {
  return HuertaNotifier(ref.read(firestoreServiceProvider), ref);
});

final lecturasSensorProvider = FutureProvider<List<LecturaSensor>>((ref) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getLecturasSensor('mock-huerta-001');
});

class HuertaNotifier extends StateNotifier<AsyncValue<Huerta?>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  HuertaNotifier(this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  Future<void> loadHuerta() async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(authServiceProvider).getCurrentUser();
      if (user != null) {
        final huerta = await _firestoreService.getHuerta(user.uid);
        state = AsyncValue.data(huerta);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> saveHuerta(Huerta huerta) async {
    await _firestoreService.saveHuerta(huerta);
    state = AsyncValue.data(huerta);
  }

  Future<void> addPlantas(List<String> plantaIds, int nivel) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final nuevas = plantaIds.map((id) => PlantaInstalada(
      plantaId: id,
      nivel: nivel,
      fechaPlantacion: DateTime.now(),
    )).toList();
    final updated = current.copyWith(plantas: [...current.plantas, ...nuevas]);
    await saveHuerta(updated);
  }
}
