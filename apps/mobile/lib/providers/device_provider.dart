import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hydrostack_device.dart';
import '../services/device_service.dart';
import '../services/firebase_init.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  if (!firebaseReady) return const UnavailableDeviceService();
  return FirebaseDeviceService();
});

final ownedDevicesProvider = FutureProvider<List<HydroStackDevice>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return const [];
  return ref.watch(deviceServiceProvider).listOwnedDevices(user.uid);
});

/// Single authority used by production hardware access.
///
/// SharedPreferences stores only a preferred ID. The selected value is valid
/// only after DeviceService confirms that `devices/{deviceId}.ownerUid` matches
/// the authenticated Firebase UID.
final authorizedDeviceProvider = FutureProvider<HydroStackDevice?>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return null;

  final preferredId = ref.watch(
    settingsProvider.select((settings) => settings.preferredDeviceId),
  );

  return ref.watch(deviceServiceProvider).resolveAuthorizedDevice(
        uid: user.uid,
        preferredDeviceId: preferredId,
      );
});
