import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/wokwi_provider.dart';
import '../../providers/notification_engine.dart';
import '../../services/notification_service.dart';
import 'home_tranquilo.dart' show HomeTranquilo;
import 'home_inteligente.dart' show HomeInteligente;
import 'home_experto.dart' show HomeExperto;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // La telemetría se auto-gestiona en wokwiLecturaProvider (simulador o
      // hardware RTDB según ajustes). Aquí solo inicializamos notificaciones.
      final notif = ref.read(notificationServiceProvider);
      await notif.initialize();
      await notif.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(userModeProvider);
    // Mantiene vivo el motor de notificaciones (evalúa la telemetría).
    ref.watch(notificationEngineProvider);
    // Registra la hora de cada lectura (detección de pérdida de señal).
    ref.listen(wokwiLecturaProvider, (_, next) {
      if (next.hasValue) {
        ref.read(ultimaLecturaProvider.notifier).state = DateTime.now();
      }
    });

    switch (mode) {
      case AppMode.basic:
        return const HomeTranquilo();
      case AppMode.eco:
        return const HomeInteligente();
      case AppMode.pro:
        return const HomeExperto();
    }
  }
}
