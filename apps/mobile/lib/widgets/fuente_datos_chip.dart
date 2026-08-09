import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/wokwi_provider.dart';
import '../theme/colors.dart';

/// Chip que indica la fuente de datos activa y su salud:
/// - SIMULACIÓN            (fuente local, gris/teal)
/// - {ID} · EN VIVO        (hardware, lectura reciente, verde)
/// - {ID} · SIN SEÑAL      (hardware, sin lecturas hace >45 s, rojo)
/// - {ID} · CONECTANDO     (hardware, aún sin primera lectura, ámbar)
class FuenteDatosChip extends ConsumerStatefulWidget {
  const FuenteDatosChip({super.key});

  @override
  ConsumerState<FuenteDatosChip> createState() => _FuenteDatosChipState();
}

class _FuenteDatosChipState extends ConsumerState<FuenteDatosChip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Reevalúa la antigüedad de la última lectura periódicamente,
    // incluso si no llegan datos nuevos (que es justo el caso a detectar).
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usarHardware = ref.watch(settingsProvider.select((s) => s.usarHardware));
    final deviceId = ref.watch(settingsProvider.select((s) => s.deviceId));
    final ultima = ref.watch(ultimaLecturaProvider);

    final IconData icon;
    final String label;
    final Color color;

    if (!usarHardware) {
      icon = Icons.computer_rounded;
      label = 'SIMULACIÓN';
      color = AppColors.gris;
    } else if (ultima == null) {
      icon = Icons.wifi_find_rounded;
      label = '$deviceId · CONECTANDO';
      color = AppColors.warning;
    } else {
      final edad = DateTime.now().difference(ultima);
      // El firmware publica cada 10 s; >45 s sin datos = señal perdida.
      if (edad.inSeconds > 45) {
        icon = Icons.sensors_off_rounded;
        label = '$deviceId · SIN SEÑAL';
        color = AppColors.danger;
      } else {
        icon = Icons.sensors_rounded;
        label = '$deviceId · EN VIVO';
        color = AppColors.circuit;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
            color: color,
          )),
        ],
      ),
    );
  }
}
