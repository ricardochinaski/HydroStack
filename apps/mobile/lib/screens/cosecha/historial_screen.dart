import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

final cosechasProvider = FutureProvider((ref) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getCosechas('mock-huerta-001');
});

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cosechasAsync = ref.watch(cosechasProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Mi Historial')),
      body: cosechasAsync.when(
        data: (cosechas) {
          if (cosechas.isEmpty) {
            return Center(child: Text('Aún no has registrado cosechas',
              style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant),
            ));
          }
          final totalGramos = cosechas.fold<double>(0, (sum, c) => sum + c.gramos);

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Text('TOTAL COSECHADO',
                      style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 4),
                    Text(totalGramos.toStringAsFixed(0),
                      style: AppTypography.metricStyle.copyWith(color: AppColors.profundo),
                    ),
                    Text('GRAMOS',
                      style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 4),
                    Text('${cosechas.length} cosechas registradas',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text('REGISTRO DE COSECHAS',
                style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 10),
              ...cosechas.map((c) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(14),
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
                    Text(c.emoji, style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.plantaNombre, style: TextStyle(
                            fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface,
                          )),
                          Text('${c.gramos}g • ${_formatDate(c.fecha)}',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          if (c.nota != null) Text(c.nota!,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
