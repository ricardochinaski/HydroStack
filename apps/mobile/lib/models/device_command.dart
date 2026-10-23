enum DeviceCommandStatus {
  applied,
  duplicate,
  rejected,
  expired,
  unknown,
}

class DeviceCommandAck {
  final String actuator;
  final String commandId;
  final DeviceCommandStatus status;
  final String code;
  final int? atMs;

  const DeviceCommandAck({
    required this.actuator,
    required this.commandId,
    required this.status,
    required this.code,
    this.atMs,
  });

  bool get succeeded =>
      status == DeviceCommandStatus.applied ||
      status == DeviceCommandStatus.duplicate;

  factory DeviceCommandAck.fromMap(
    String actuator,
    Map<String, dynamic> data,
  ) {
    return DeviceCommandAck(
      actuator: actuator,
      commandId: data['commandId']?.toString() ?? '',
      status: _statusFromString(data['status']?.toString()),
      code: data['code']?.toString() ?? '',
      atMs: (data['at'] as num?)?.toInt(),
    );
  }

  static DeviceCommandStatus _statusFromString(String? value) {
    switch (value) {
      case 'APPLIED':
        return DeviceCommandStatus.applied;
      case 'DUPLICATE':
        return DeviceCommandStatus.duplicate;
      case 'REJECTED':
        return DeviceCommandStatus.rejected;
      case 'EXPIRED':
        return DeviceCommandStatus.expired;
      default:
        return DeviceCommandStatus.unknown;
    }
  }
}
