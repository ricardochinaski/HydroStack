import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/huerta.dart';
import '../models/lectura_sensor.dart';
import '../models/alerta.dart';
import '../models/cosecha.dart';
import '../models/planta.dart';
import 'firestore_service.dart';

/// Implementación real de Firestore para los DATOS DE USUARIO
/// (perfil/modo, huerta y cosechas). Los datos de dispositivo (catálogo de
/// plantas, lecturas y alertas semilla) se delegan al mock, ya que las
/// lecturas en vivo llegan por la telemetría del ESP32.
class FirebaseFirestoreService implements FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _seed = MockFirestoreService();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _usuarios => _db.collection('usuarios');

  // --- Datos de dispositivo (delegados al mock) ---
  @override
  Future<List<Planta>> getCatalogoPlantas() => _seed.getCatalogoPlantas();

  @override
  Future<List<LecturaSensor>> getLecturasSensor(String huertaId) => _seed.getLecturasSensor(huertaId);

  @override
  Future<List<Alerta>> getAlertas(String huertaId) => _seed.getAlertas(huertaId);

  @override
  Future<void> marcarAlertaResuelta(String alertaId) => _seed.marcarAlertaResuelta(alertaId);

  // --- Datos de usuario (Firestore real) ---
  @override
  Future<void> saveUserMode(String uid, String mode) async {
    await _usuarios.doc(uid).set({'mode': mode}, SetOptions(merge: true));
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    final uid = _uid;
    if (uid == null) return;
    await _usuarios.doc(uid).set({
      'deviceId': deviceId,
      'deviceVinculadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Huerta?> getHuerta(String userId) async {
    final doc = await _usuarios.doc(userId).collection('huerta').doc('config').get();
    final data = doc.data();
    if (data == null) {
      return const Huerta(id: 'default', nombre: 'Mi Huerta Viva', esp32Connected: false);
    }
    return Huerta(
      id: doc.id,
      nombre: data['nombre'] as String? ?? 'Mi Huerta Viva',
      capacidadMaxima: (data['capacidadMaxima'] as num?)?.toInt() ?? 24,
      esp32Connected: data['esp32Connected'] as bool? ?? false,
      esp32Id: data['esp32Id'] as String?,
      plantas: ((data['plantas'] as List<dynamic>?) ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return PlantaInstalada(
          plantaId: m['plantaId'] as String,
          nivel: (m['nivel'] as num?)?.toInt() ?? 1,
          fechaPlantacion: (m['fechaPlantacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
          activa: m['activa'] as bool? ?? true,
        );
      }).toList(),
    );
  }

  @override
  Future<void> saveHuerta(Huerta huerta) async {
    final uid = _uid;
    if (uid == null) return;
    await _usuarios.doc(uid).collection('huerta').doc('config').set({
      'nombre': huerta.nombre,
      'capacidadMaxima': huerta.capacidadMaxima,
      'esp32Connected': huerta.esp32Connected,
      'esp32Id': huerta.esp32Id,
      'plantas': huerta.plantas.map((p) => {
        'plantaId': p.plantaId,
        'nivel': p.nivel,
        'fechaPlantacion': Timestamp.fromDate(p.fechaPlantacion),
        'activa': p.activa,
      }).toList(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<RegistroCosecha>> getCosechas(String huertaId) async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _usuarios.doc(uid).collection('cosechas').orderBy('fecha', descending: true).get();
    return snap.docs.map((d) {
      final m = d.data();
      return RegistroCosecha(
        id: d.id,
        plantaId: m['plantaId'] as String? ?? '',
        plantaNombre: m['plantaNombre'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '🌱',
        gramos: (m['gramos'] as num?)?.toDouble() ?? 0,
        fecha: (m['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
        nota: m['nota'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> registrarCosecha(RegistroCosecha cosecha) async {
    final uid = _uid;
    if (uid == null) return;
    await _usuarios.doc(uid).collection('cosechas').add({
      'plantaId': cosecha.plantaId,
      'plantaNombre': cosecha.plantaNombre,
      'emoji': cosecha.emoji,
      'gramos': cosecha.gramos,
      'fecha': Timestamp.fromDate(cosecha.fecha),
      'nota': cosecha.nota,
    });
  }
}
