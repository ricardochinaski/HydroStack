import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hydrostack_device.dart';

abstract class DeviceService {
  Future<List<HydroStackDevice>> listOwnedDevices(String uid);

  Future<HydroStackDevice?> getOwnedDevice(String uid, String deviceId);

  Future<bool> ownsDevice(String uid, String deviceId) async {
    return await getOwnedDevice(uid, deviceId) != null;
  }

  /// Resolves the device that is allowed to be used for production RTDB access.
  /// A locally stored ID is only a preference; Firestore ownership remains the
  /// authority. If the preferred ID is no longer owned, it is rejected.
  Future<HydroStackDevice?> resolveAuthorizedDevice({
    required String uid,
    String? preferredDeviceId,
  });

  /// Only mutable presentation metadata is client-editable in this phase.
  Future<void> updateAlias(String uid, String deviceId, String alias);
}

class FirebaseDeviceService implements DeviceService {
  final FirebaseFirestore _db;

  FirebaseDeviceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _devices =>
      _db.collection('devices');

  @override
  Future<List<HydroStackDevice>> listOwnedDevices(String uid) async {
    if (uid.isEmpty) return const [];
    final snap = await _devices.where('ownerUid', isEqualTo: uid).get();
    return snap.docs
        .where((doc) => _hasCanonicalIdentity(doc))
        .map(_fromDocument)
        .toList(growable: false);
  }

  @override
  Future<HydroStackDevice?> getOwnedDevice(String uid, String deviceId) async {
    final normalizedId = deviceId.trim();
    if (uid.isEmpty || normalizedId.isEmpty) return null;
    final snap = await _devices.doc(normalizedId).get();
    if (!snap.exists || snap.data() == null || !_hasCanonicalIdentity(snap)) {
      return null;
    }
    final device = _fromDocument(snap);
    return device.isOwnedBy(uid) ? device : null;
  }

  @override
  Future<HydroStackDevice?> resolveAuthorizedDevice({
    required String uid,
    String? preferredDeviceId,
  }) async {
    if (uid.isEmpty) return null;

    final preferred = preferredDeviceId?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      final owned = await getOwnedDevice(uid, preferred);
      if (owned != null) return owned;
    }

    final snap = await _devices
        .where('ownerUid', isEqualTo: uid)
        .limit(10)
        .get();
    for (final doc in snap.docs) {
      if (_hasCanonicalIdentity(doc)) return _fromDocument(doc);
    }
    return null;
  }

  @override
  Future<void> updateAlias(String uid, String deviceId, String alias) async {
    final normalizedAlias = alias.trim();
    if (normalizedAlias.isEmpty || normalizedAlias.length > 80) {
      throw ArgumentError('El alias debe contener entre 1 y 80 caracteres.');
    }

    final owned = await getOwnedDevice(uid, deviceId);
    if (owned == null) {
      throw StateError('El dispositivo no pertenece al usuario autenticado.');
    }
    await _devices.doc(owned.deviceId).update({
      'alias': normalizedAlias,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _hasCanonicalIdentity(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final storedId = data?['deviceId'];
    return storedId is String && storedId.trim() == doc.id;
  }

  HydroStackDevice _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawOwnerUid = data['ownerUid'];
    final rawAlias = data['alias'];
    final rawStatus = data['status'];

    return HydroStackDevice(
      deviceId: doc.id,
      ownerUid: rawOwnerUid is String ? rawOwnerUid : '',
      alias: rawAlias is String && rawAlias.trim().isNotEmpty
          ? rawAlias.trim()
          : doc.id,
      status: _statusFromString(rawStatus is String ? rawStatus : null),
      claimedAt: _date(data['claimedAt']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  HydroStackDeviceStatus _statusFromString(String? value) {
    switch (value) {
      case 'provisioning':
        return HydroStackDeviceStatus.provisioning;
      case 'online':
        return HydroStackDeviceStatus.online;
      case 'offline':
        return HydroStackDeviceStatus.offline;
      case 'disabled':
        return HydroStackDeviceStatus.disabled;
      default:
        return HydroStackDeviceStatus.unknown;
    }
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class UnavailableDeviceService implements DeviceService {
  const UnavailableDeviceService();

  @override
  Future<List<HydroStackDevice>> listOwnedDevices(String uid) async => const [];

  @override
  Future<HydroStackDevice?> getOwnedDevice(String uid, String deviceId) async => null;

  @override
  Future<HydroStackDevice?> resolveAuthorizedDevice({
    required String uid,
    String? preferredDeviceId,
  }) async => null;

  @override
  Future<void> updateAlias(String uid, String deviceId, String alias) async {
    throw StateError('Firebase no está disponible; no existe ownership verificable.');
  }
}
