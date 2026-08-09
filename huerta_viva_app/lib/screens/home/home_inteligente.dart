import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../models/user.dart';
import '../../models/lectura_sensor.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wokwi_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/alertas_bell.dart';
import '../../widgets/fuente_datos_chip.dart';
import '../../utils/icon_assets.dart';
import 'home_status_banner.dart';

class HomeInteligente extends ConsumerWidget {
  const HomeInteligente({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertas = ref.watch(alertasProvider).valueOrNull ?? [];
    final pendientes = alertas.where((a) => !a.resuelta).toList();
    final settings = ref.watch(settingsProvider);
    final telemetria = ref.watch(wokwiLecturaProvider);
    final sensores = telemetria.valueOrNull != null
        ? sensoresDesdeTelemetria(telemetria.value!, AppMode.eco)
        : <LecturaSensor>[];

    final t = telemetria.valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.ecoBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco_rounded, size: 14, color: AppColors.eco),
                        const SizedBox(width: 6),
                        Text('ECO', style: AppTypography.techLabel.copyWith(color: AppColors.eco)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const AlertasBell(),
                ],
              ),
              const SizedBox(height: 16),
              HomeStatusBanner(sensores: sensores, alertasPendientes: pendientes.length),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('En vivo', style: TextStyle(
                    fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
                  )),
                  const Spacer(),
                  const FuenteDatosChip(),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  StatCard(
                    icon: Icons.science_outlined,
                    metric: t != null ? t.ph.toStringAsFixed(1) : '--',
                    label: 'pH agua',
                    progress: t != null ? ((t.ph - 5.0) / 2.0).clamp(0.0, 1.0) : 0,
                    accentColor: _estadoColor(sensores, 'pH agua'),
                  ),
                  StatCard(
                    icon: Icons.thermostat_rounded,
                    metric: t != null ? settings.formatTemp(t.tempAgua) : '--',
                    label: 'Temp. agua',
                    progress: t != null ? ((t.tempAgua - 14) / 14).clamp(0.0, 1.0) : 0,
                    accentColor: _estadoColor(sensores, 'Temperatura agua'),
                  ),
                  StatCard(
                    icon: Icons.water_drop_rounded,
                    metric: t != null ? t.nivelAgua.toStringAsFixed(0) : '--',
                    unit: '%',
                    label: 'Nivel agua',
                    progress: t != null ? (t.nivelAgua / 100).clamp(0.0, 1.0) : 0,
                    accentColor: _estadoColor(sensores, 'Nivel agua'),
                  ),
                  StatCard(
                    icon: Icons.cloud_outlined,
                    metric: t != null ? t.humedadAmbiente.toStringAsFixed(0) : '--',
                    unit: '%',
                    label: 'Humedad',
                    progress: t != null ? (t.humedadAmbiente / 100).clamp(0.0, 1.0) : 0,
                    accentColor: _estadoColor(sensores, 'Humedad ambiente'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/riego-manual'),
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Regar ahora'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/plantas'),
                      icon: const Icon(Icons.eco),
                      label: const Text('Mis plantas'),
                    ),
                  ),
                ],
              ),
              if (pendientes.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Alertas activas', style: TextStyle(
                  fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
                )),
                const SizedBox(height: 12),
                ...pendientes.take(3).map((a) => Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(iconFromEmoji(a.icon), size: 20, color: AppColors.profundo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.titulo, style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface,
                        )),
                      ),
                    ],
                  ),
                )),
                TextButton(
                  onPressed: () => context.push('/centro-alertas'),
                  child: const Text('Ver todas las alertas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _estadoColor(List<LecturaSensor> sensores, String nombre) {
    final s = sensores.where((x) => x.sensorName == nombre);
    if (s.isEmpty) return AppColors.profundo;
    switch (s.first.estado) {
      case SensorEstado.ok: return AppColors.profundo;
      case SensorEstado.warn: return AppColors.warning;
      case SensorEstado.danger: return AppColors.danger;
    }
  }
}
