enum HydroStackDeviceStatus {
  unknown,
  provisioning,
  online,
  offline,
  disabled,
}

class HydroStackDevice {
  final String deviceId;
  final String ownerUid;
  final String alias;
  final HydroStackDeviceStatus status;
  final DateTime? claimedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HydroStackDevice({
    required this.deviceId,
    required this.ownerUid,
    required this.alias,
    this.status = HydroStackDeviceStatus.unknown,
    this.claimedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool isOwnedBy(String uid) => ownerUid == uid;

  HydroStackDevice copyWith({
    String? alias,
    HydroStackDeviceStatus? status,
    DateTime? claimedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HydroStackDevice(
      deviceId: deviceId,
      ownerUid: ownerUid,
      alias: alias ?? this.alias,
      status: status ?? this.status,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
