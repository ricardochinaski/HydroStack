import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wokwi_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class RiegoManualScreen extends ConsumerStatefulWidget {
  const RiegoManualScreen({super.key});

  @override
  ConsumerState<RiegoManualScreen> createState() => _RiegoManualScreenState();
}

class _RiegoManualScreenState extends ConsumerState<RiegoManualScreen> {
  double _minutes = 10;
  bool _regando = false;
  bool _completado = false;

  // Duración real del pulso de la bomba en el firmware (ver HidroSmart_Mega.ino).
  static const _duracionPulso = Duration(seconds: 5);

  Future<void> _startRiego() async {
    setState(() => _regando = true);
    await enviarComando(ref, 'bomba', '1');
    Future.delayed(_duracionPulso, () {
      if (mounted) {
        setState(() {
          _regando = false;
          _completado = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color stateColor = AppColors.profundo;
    if (_regando) stateColor = AppColors.circuit;
    if (_completado) stateColor = AppColors.profundo;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Riego Manual')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: _regando ? AppColors.circuitBg : AppColors.profundoBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  _regando ? Icons.water_drop_rounded : _completado ? Icons.check_circle_rounded : Icons.shower_rounded,
                  size: 48,
                  color: _regando ? AppColors.circuit : AppColors.profundo,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _regando ? 'Regando...' : _completado ? 'Riego completado' : '¿Cuánto tiempo regar?',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _regando ? 'La bomba está funcionando' : _completado ? 'Tus plantas recibieron agua' : 'Selecciona la duración del riego',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (!_regando && !_completado) ...[
              const SizedBox(height: 32),
              Text('${_minutes.toInt()}',
                style: AppTypography.metricStyle.copyWith(fontSize: 32, color: stateColor),
              ),
              Text('MINUTOS',
                style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text('(referencial — el pulso real de la bomba dura 5 s por seguridad)',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _minutes,
                min: 5, max: 30, divisions: 5,
                label: '${_minutes.toInt()} min',
                activeColor: stateColor,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startRiego,
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Regar ahora'),
                ),
              ),
            ],
            if (_completado) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _regando = false;
                    _completado = false;
                  }),
                  child: const Text('Regar de nuevo'),
                ),
              ),
            ],
            if (_regando) ...[
              const SizedBox(height: 20),
              CircularProgressIndicator(color: AppColors.circuit),
            ],
          ],
        ),
      ),
    );
  }
}
