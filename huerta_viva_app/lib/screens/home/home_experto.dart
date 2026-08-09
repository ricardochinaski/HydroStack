import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../models/user.dart';
import '../../models/lectura_sensor.dart';
import '../../providers/wokwi_provider.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/alertas_bell.dart';
import '../../widgets/fuente_datos_chip.dart';
import 'home_status_banner.dart';

class HomeExperto extends ConsumerStatefulWidget {
  const HomeExperto({super.key});

  @override
  ConsumerState<HomeExperto> createState() => _HomeExpertoState();
}

class _HomeExpertoState extends ConsumerState<HomeExperto> {
  final List<double> _phHistory = [];

  @override
  Widget build(BuildContext context) {
    // Acumula el historial de pH a medida que llega telemetría.
    ref.listen(wokwiLecturaProvider, (prev, next) {
      next.whenData((t) {
        _phHistory.add(t.ph);
        if (_phHistory.length > 30) _phHistory.removeAt(0);
        if (mounted) setState(() {});
      });
    });

    final telemetria = ref.watch(wokwiLecturaProvider);
    final t = telemetria.valueOrNull;
    final sensores = t != null ? sensoresDesdeTelemetria(t, AppMode.pro) : <LecturaSensor>[];

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
                    decoration: BoxDecoration(color: AppColors.proBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: AppColors.pro),
                        const SizedBox(width: 6),
                        Text('PRO', style: TextStyle(
                          fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 1,
                          fontWeight: FontWeight.w500, color: AppColors.pro,
                        )),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const AlertasBell(),
                ],
              ),
              const SizedBox(height: 16),
              HomeStatusBanner(sensores: sensores),
              const SizedBox(height: 16),
              if (t != null) _dosingRow(context, t),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Sensores en vivo', style: TextStyle(
                    fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
                  )),
                  const Spacer(),
                  const FuenteDatosChip(),
                ],
              ),
              const SizedBox(height: 12),
              if (t == null)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else
                ...sensores.map((l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SensorCard(lectura: l))),
              const SizedBox(height: 20),
              Text('pH — EN VIVO', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: SizedBox(height: 120, child: _phChart(context)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/panel-sensores'),
                      icon: const Icon(Icons.sensors),
                      label: const Text('Ver todos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/programar-riego'),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Programar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dosingRow(BuildContext context, dynamic t) {
    final relays = (t.relays as List).cast<int>();
    final nut = relays.isNotEmpty && relays[0] == 1;
    final ph = relays.length > 1 && relays[1] == 1;
    final led = relays.length > 2 && relays[2] == 1;
    final bomba = relays.length > 3 && relays[3] == 1;
    return Row(
      children: [
        _dosChip(context, Icons.science_outlined, 'Nutrientes', nut, AppColors.pro),
        const SizedBox(width: 8),
        _dosChip(context, Icons.water_drop_outlined, 'pH-', ph, AppColors.circuit),
        const SizedBox(width: 8),
        _dosChip(context, Icons.light_mode_outlined, 'Luz', led, AppColors.warning),
        const SizedBox(width: 8),
        _dosChip(context, Icons.water_rounded, 'Bomba', bomba, AppColors.info),
      ],
    );
  }

  Widget _dosChip(BuildContext context, IconData icon, String label, bool active, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 3),
            Text('$label ${active ? 'ON' : 'OFF'}', style: TextStyle(
              fontFamily: 'JetBrains Mono', fontSize: 8.5, letterSpacing: 0.5,
              color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }

  Widget _phChart(BuildContext context) {
    if (_phHistory.length < 2) {
      return Center(child: Text('Acumulando datos...', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }
    final spots = [for (var i = 0; i < _phHistory.length; i++) FlSpot(i.toDouble(), _phHistory[i])];
    return LineChart(
      LineChartData(
        minY: 4.5, maxY: 8.5,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (v) => FlLine(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), strokeWidth: 0.5),
          drawVerticalLine: false,
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.circuit,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.circuit.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }
}
