import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planta.dart';
import '../data/plantas_data.dart';
import '../services/firestore_service.dart';

final catalogoPlantasProvider = FutureProvider<List<Planta>>((ref) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getCatalogoPlantas();
});

final plantaDetailProvider = Provider.family<Planta?, String>((ref, String id) {
  return PlantasData.getById(id);
});

final filterProvider = StateProvider<String>((ref) => 'todas');

final filteredPlantasProvider = Provider<List<Planta>>((ref) {
  final filter = ref.watch(filterProvider);
  final allPlantas = ref.watch(catalogoPlantasProvider).valueOrNull ?? PlantasData.plantas;
  if (filter == 'todas') return allPlantas;
  if (filter == 'facil') return allPlantas.where((p) => p.difficulty == 'facil').toList();
  return allPlantas.where((p) => p.category == filter).toList();
});
