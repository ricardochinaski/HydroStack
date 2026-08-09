import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/huerta.dart';
import '../models/lectura_sensor.dart';
import '../models/alerta.dart';
import '../models/cosecha.dart';
import '../models/planta.dart';
import '../data/plantas_data.dart';
import 'firebase_firestore_service.dart';
import 'firebase_init.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return firebaseReady ? FirebaseFirestoreService() : MockFirestoreService();
});

abstract class FirestoreService {
  Future<void> saveUserMode(String uid, String mode);
  /// Vincula un dispositivo físico (ej. "HS-001") a la cuenta del usuario actual.
  Future<void> saveDeviceId(String deviceId);
  Future<List<Planta>> getCatalogoPlantas();
  Future<Huerta?> getHuerta(String userId);
  Future<void> saveHuerta(Huerta huerta);
  Future<List<LecturaSensor>> getLecturasSensor(String huertaId);
  Future<List<Alerta>> getAlertas(String huertaId);
  Future<void> marcarAlertaResuelta(String alertaId);
  Future<List<RegistroCosecha>> getCosechas(String huertaId);
  Future<void> registrarCosecha(RegistroCosecha cosecha);
}

class MockFirestoreService implements FirestoreService {
  @override
  Future<void> saveUserMode(String uid, String mode) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<Planta>> getCatalogoPlantas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PlantasData.plantas;
  }

  @override
  Future<Huerta?> getHuerta(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Huerta(
      id: 'mock-huerta-001',
      nombre: 'Mi Huerta Viva',
      esp32Connected: false,
    );
  }

  @override
  Future<void> saveHuerta(Huerta huerta) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<LecturaSensor>> getLecturasSensor(String huertaId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      LecturaSensor(id: 's1', sensorName: 'Temperatura ambiente', icon: '🌡️', unidad: '°C', valor: 22.5, minOptimo: 18, maxOptimo: 28, timestamp: now),
      LecturaSensor(id: 's2', sensorName: 'Humedad ambiente', icon: '💧', unidad: '%', valor: 65, minOptimo: 50, maxOptimo: 80, timestamp: now),
      LecturaSensor(id: 's3', sensorName: 'Temperatura agua', icon: '🌊', unidad: '°C', valor: 21.0, minOptimo: 18, maxOptimo: 24, timestamp: now),
      LecturaSensor(id: 's4', sensorName: 'Nivel agua', icon: '📏', unidad: '%', valor: 75, minOptimo: 20, maxOptimo: 100, timestamp: now),
      LecturaSensor(id: 's5', sensorName: 'pH agua', icon: '⚗️', unidad: 'pH', valor: 6.1, minOptimo: 5.5, maxOptimo: 6.5, timestamp: now, rango: '5.5–6.5'),
      LecturaSensor(id: 's6', sensorName: 'EC nutrientes', icon: '🔬', unidad: 'mS/cm', valor: 1.8, minOptimo: 1.2, maxOptimo: 2.0, timestamp: now, rango: '1.2–2.0'),
    ];
  }

  @override
  Future<List<Alerta>> getAlertas(String huertaId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      Alerta(id: 'a1', icon: '💧', titulo: 'Agua baja', descripcion: 'El reservorio está al 18%. Agrega unos 3 litros de agua.', prioridad: Prioridad.urgente, fecha: now.subtract(const Duration(hours: 2)), accionLabel: 'Agregar agua'),
      Alerta(id: 'a2', icon: '🌡️', titulo: 'Temperatura alta', descripcion: 'La temperatura superó los 30°C. Mueve la torre a la sombra.', prioridad: Prioridad.atencion, fecha: now.subtract(const Duration(hours: 5))),
      Alerta(id: 'a3', icon: '✂️', titulo: 'Albahaca lista', descripcion: 'Tu albahaca está lista para cosechar. Revisa la guía.', prioridad: Prioridad.info, fecha: now.subtract(const Duration(days: 1)), resuelta: true),
      Alerta(id: 'a4', icon: '🌱', titulo: 'Cambio de agua', descripcion: 'Han pasado 2 semanas. Cambia el agua del reservorio.', prioridad: Prioridad.atencion, fecha: now.subtract(const Duration(days: 3))),
      Alerta(id: 'a5', icon: '🎉', titulo: 'Primera cosecha', descripcion: 'Llevas 30 días cultivando. ¡Felicidades!', prioridad: Prioridad.info, fecha: now.subtract(const Duration(days: 10)), resuelta: true),
    ];
  }

  @override
  Future<void> marcarAlertaResuelta(String alertaId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<RegistroCosecha>> getCosechas(String huertaId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      RegistroCosecha(id: 'c1', plantaId: 'albahaca', plantaNombre: 'Albahaca', emoji: '🌿', gramos: 120, fecha: now.subtract(const Duration(days: 15)), nota: 'Primera cosecha'),
      RegistroCosecha(id: 'c2', plantaId: 'lechuga', plantaNombre: 'Lechuga', emoji: '🥬', gramos: 250, fecha: now.subtract(const Duration(days: 20))),
      RegistroCosecha(id: 'c3', plantaId: 'cilantro', plantaNombre: 'Cilantro', emoji: '🌱', gramos: 60, fecha: now.subtract(const Duration(days: 25))),
    ];
  }

  @override
  Future<void> registrarCosecha(RegistroCosecha cosecha) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
