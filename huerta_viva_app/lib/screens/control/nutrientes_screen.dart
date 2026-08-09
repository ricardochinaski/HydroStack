import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class NutrientesScreen extends StatefulWidget {
  const NutrientesScreen({super.key});

  @override
  State<NutrientesScreen> createState() => _NutrientesScreenState();
}

class _NutrientesScreenState extends State<NutrientesScreen> {
  bool _isPro = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Solución Nutritiva')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VERSIÓN PRO', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        SizedBox(height: 2),
                        Text(_isPro ? 'Dosificación automática activada' : 'Modo manual — ECO',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPro,
                    activeThumbColor: AppColors.pro,
                    onChanged: (v) => setState(() => _isPro = v),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (_isPro) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.proBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pro.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.rocket_launch_rounded, size: 18, color: AppColors.pro),
                      SizedBox(width: 8),
                      Text('Dosificación automática PRO',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pro),
                      ),
                    ]),
                    SizedBox(height: 8),
                    Text('Los sensores EC miden la concentración de nutrientes en tiempo real. Las bombas peristálticas dosifican automáticamente.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text('EC', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          SizedBox(height: 4),
                          Text('1.8', style: AppTypography.metricSmall.copyWith(color: AppColors.profundo)),
                          Text('mS/cm', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                        Column(children: [
                          Text('PH', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          SizedBox(height: 4),
                          Text('6.1', style: AppTypography.metricSmall.copyWith(color: AppColors.profundo)),
                          Text(' ', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                        Column(children: [
                          Text('ESTADO', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          SizedBox(height: 4),
                          Icon(Icons.check_circle_rounded, size: 24, color: AppColors.profundo),
                          Text('OK', style: AppTypography.techLabelSmall.copyWith(color: AppColors.profundo)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.profundoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.profundo.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.eco_rounded, size: 18, color: AppColors.profundo),
                      SizedBox(width: 8),
                      Text('Modo Manual — ECO',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.profundo),
                      ),
                    ]),
                    SizedBox(height: 8),
                    Text('Sigue estos pasos para preparar la solución nutritiva:',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 12),
                    _step(context, '1', 'Agrega 15 mL de nutriente A'),
                    _step(context, '2', 'Agrega 12 mL de nutriente B'),
                    _step(context, '3', 'Mezcla bien en el reservorio'),
                    _step(context, '4', 'Repite cada 2 semanas'),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RECORDATORIO', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  SizedBox(height: 8),
                  Text('Próximo cambio de solución: en 5 días',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.notifications_outlined),
                      label: Text('Recordarme en 2 semanas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(BuildContext context, String num, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.profundoBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(num, style: TextStyle(
              fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.profundo,
            ))),
          ),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
