import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Acerca de HidroSmart')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: AppColors.profundo.withValues(alpha: 0.14), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Image.asset('assets/images/app_icon.png'),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text('HidroSmart', style: TextStyle(
              fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface,
            )),
          ),
          SizedBox(height: 4),
          Center(
            child: Text('Versión 1.0.0 (build 1)',
              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              'HidroSmart es una app para el control de huertas verticales hidropónicas mediante un controlador ESP32. '
              'Monitorea pH, temperatura, nivel de agua y nutrientes, y administra el riego en modo eco, autónomo o pro.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.code, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Desarrollado con Flutter', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.memory, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Hardware: ESP32', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: Text('© 2026 HidroSmart. Todos los derechos reservados.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
