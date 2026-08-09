import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wokwi_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/fuente_datos_chip.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class PanelSensoresScreen extends ConsumerWidget {
  const PanelSensoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetria = ref.watch(wokwiLecturaProvider);
    final modo = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('CONTROL RÁPIDO', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(
            children: [
              _accion(context, Icons.water_drop_rounded, 'Regar', AppColors.circuit, () => context.push('/riego-manual')),
              const SizedBox(width: 10),
              _accion(context, Icons.schedule_rounded, 'Programar', AppColors.info, () => context.push('/programar-riego')),
              const SizedBox(width: 10),
              _accion(context, Icons.science_outlined, 'Nutrientes', AppColors.pro, () => context.push('/nutrientes')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('SENSORES', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              const FuenteDatosChip(),
            ],
          ),
          const SizedBox(height: 10),
          if (modo == AppMode.basic)
            _sinSensores(context)
          else
            telemetria.when(
              data: (t) {
                final sensores = sensoresDesdeTelemetria(t, modo);
                return Column(
                  children: sensores
                      .map((l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SensorCard(lectura: l)))
                      .toList(),
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Sin telemetría: $e'))),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sinSensores(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, color: AppColors.circuit, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modelo Basic', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('Tu huerta solo tiene bomba circuladora, sin sensores. Mejora a Eco o Pro para ver pH, temperatura y nivel en vivo.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accion(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
