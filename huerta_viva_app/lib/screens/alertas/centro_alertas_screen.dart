import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/alertas_provider.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class CentroAlertasScreen extends ConsumerWidget {
  const CentroAlertasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertasAsync = ref.watch(alertasProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Centro de Alertas')),
      body: alertasAsync.when(
        data: (alertas) {
          if (alertas.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_rounded,
              title: 'Sin alertas',
              subtitle: 'Tu huerta está funcionando sin problemas',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {}, // las alertas se actualizan en vivo
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text('ÚLTIMOS 30 DÍAS',
                      style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warnBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${alertas.where((a) => !a.resuelta).length} PENDIENTES',
                        style: AppTypography.techLabelSmall.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...alertas.map((a) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: AlertCard(
                    alerta: a,
                    onResolve: a.resuelta ? null : () {
                      ref.read(alertasProvider.notifier).marcarResuelta(a.id);
                    },
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
