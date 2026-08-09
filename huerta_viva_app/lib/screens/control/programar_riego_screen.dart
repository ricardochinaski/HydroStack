import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class ProgramarRiegoScreen extends StatefulWidget {
  const ProgramarRiegoScreen({super.key});

  @override
  State<ProgramarRiegoScreen> createState() => _ProgramarRiegoScreenState();
}

class _ProgramarRiegoScreenState extends State<ProgramarRiegoScreen> {
  TimeOfDay _startTime = TimeOfDay(hour: 8, minute: 0);
  int _intervalHours = 2;
  int _durationMinutes = 15;
  bool _smartMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Programar Riego')),
      body: ListView(
        padding: EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Modo automático inteligente',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text('Se adapta a la temperatura y tipo de plantas',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _smartMode,
                      activeThumbColor: AppColors.circuit,
                      onChanged: (v) => setState(() => _smartMode = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
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
                Text('HORA DE INICIO', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _startTime);
                    if (picked != null) setState(() => _startTime = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: AppColors.profundo),
                        SizedBox(width: 10),
                        Text(_startTime.format(context), style: TextStyle(
                          fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface,
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
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
                Text('FRECUENCIA', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                SizedBox(height: 8),
                Text('CADA $_intervalHours HORAS',
                  style: AppTypography.techLabel.copyWith(color: AppColors.circuit),
                ),
                Slider(
                  value: _intervalHours.toDouble(),
                  min: 1, max: 6, divisions: 5,
                  activeColor: AppColors.circuit,
                  onChanged: (v) => setState(() => _intervalHours = v.toInt()),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
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
                Text('DURACIÓN', style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                SizedBox(height: 8),
                Text('$_durationMinutes MIN / CICLO',
                  style: AppTypography.techLabel.copyWith(color: AppColors.circuit),
                ),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 5, max: 30, divisions: 5,
                  activeColor: AppColors.circuit,
                  onChanged: (v) => setState(() => _durationMinutes = v.toInt()),
                ),
              ],
            ),
          ),
          if (_smartMode) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.circuitBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.circuit.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 20, color: AppColors.circuit),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Sugerido para tus plantas: cada 2 horas. Se ajustará automáticamente según la temperatura.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Horario de riego guardado')),
                );
              },
              child: Text('Guardar horario'),
            ),
          ),
        ],
      ),
    );
  }
}
