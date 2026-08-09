import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class ConectarEsp32Screen extends StatefulWidget {
  const ConectarEsp32Screen({super.key});

  @override
  State<ConectarEsp32Screen> createState() => _ConectarEsp32ScreenState();
}

class _ConectarEsp32ScreenState extends State<ConectarEsp32Screen> {
  bool _scanning = false;
  bool _connected = false;

  void _startScan() {
    setState(() => _scanning = true);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanning = false;
          _connected = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112, height: 112,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (_connected ? AppColors.circuit : AppColors.profundo).withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _connected ? Icons.check_circle_rounded : Icons.wifi_tethering_rounded,
                    size: 52,
                    color: _connected ? AppColors.circuit : AppColors.profundo,
                  ),
                ),
              ),
              SizedBox(height: 28),
              Text(
                _connected ? '¡Huerta conectada!' : 'Conecta tu huerta al WiFi',
                style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _connected
                    ? 'Tu ESP32 está listo. Vamos a agregar tus primeras plantas.'
                    : 'Asegúrate de que la huerta esté encendida. La app detectará el ESP32 por Bluetooth.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36),
              if (_scanning) ...[
                CircularProgressIndicator(color: AppColors.circuit),
                SizedBox(height: 16),
                Text('BUSCANDO DISPOSITIVO...',
                  style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ] else if (_connected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/agregar-plantas'),
                    child: Text('Continuar'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startScan,
                    icon: Icon(Icons.bluetooth_searching),
                    label: Text('Buscar ESP32'),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/agregar-plantas'),
                  child: Text('OMITIR POR AHORA',
                    style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
