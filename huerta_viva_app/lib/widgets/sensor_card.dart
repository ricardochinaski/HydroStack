import 'package:flutter/material.dart';
import '../models/lectura_sensor.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/icon_assets.dart';

class SensorCard extends StatelessWidget {
  final LecturaSensor lectura;

  const SensorCard({super.key, required this.lectura});

  Color _accentColor() {
    switch (lectura.estado) {
      case SensorEstado.ok: return AppColors.profundo;
      case SensorEstado.warn: return AppColors.warning;
      case SensorEstado.danger: return AppColors.danger;
    }
  }

  Color _accentBg() {
    switch (lectura.estado) {
      case SensorEstado.ok: return AppColors.okBg;
      case SensorEstado.warn: return AppColors.warnBg;
      case SensorEstado.danger: return AppColors.dangerBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final bg = _accentBg();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: sensorIcon(lectura.sensorName, size: 38)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lectura.sensorName.toUpperCase(),
                  style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 4),
                Text(
                  'RANGO: ${lectura.rango ?? '${lectura.minOptimo}–${lectura.maxOptimo} ${lectura.unidad}'}',
                  style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(lectura.valor.toStringAsFixed(1),
                style: AppTypography.metricSmall.copyWith(color: accent),
              ),
              Text(lectura.unidad.toUpperCase(),
                style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(lectura.estadoLabel.toUpperCase(),
                  style: AppTypography.techLabelSmall.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
