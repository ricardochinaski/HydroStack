import 'package:flutter/material.dart';
import '../../models/lectura_sensor.dart';
import '../../theme/colors.dart';

/// Banner de estado general de la huerta, derivado de los sensores en vivo
/// y la cantidad de alertas pendientes.
class HomeStatusBanner extends StatelessWidget {
  final List<LecturaSensor> sensores;
  final int alertasPendientes;

  const HomeStatusBanner({super.key, required this.sensores, this.alertasPendientes = 0});

  @override
  Widget build(BuildContext context) {
    final hayDanger = sensores.any((s) => s.estado == SensorEstado.danger);
    final hayWarn = sensores.any((s) => s.estado == SensorEstado.warn);

    late Color color;
    late Color bg;
    late IconData icon;
    late String titulo;
    late String detalle;

    if (hayDanger || alertasPendientes > 0) {
      color = AppColors.danger;
      bg = AppColors.dangerBg;
      icon = Icons.warning_amber_rounded;
      titulo = 'Atención requerida';
      final probs = <String>[];
      if (hayDanger) probs.add('parámetros fuera de rango');
      if (alertasPendientes > 0) probs.add('$alertasPendientes alerta${alertasPendientes > 1 ? 's' : ''} pendiente${alertasPendientes > 1 ? 's' : ''}');
      detalle = 'Revisa: ${probs.join(' · ')}.';
    } else if (hayWarn) {
      color = AppColors.warning;
      bg = AppColors.warnBg;
      icon = Icons.info_outline_rounded;
      titulo = 'Vigilá tu huerta';
      detalle = 'Algún parámetro está cerca del límite. Sin urgencia.';
    } else {
      color = AppColors.profundo;
      bg = AppColors.okBg;
      icon = Icons.check_circle_outline_rounded;
      titulo = 'Todo en orden';
      detalle = sensores.isEmpty
          ? 'La bomba está circulando el agua de tu huerta.'
          : 'Todos los parámetros están dentro de rango.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.carbon)),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: AppColors.carbon, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
