import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class MiHuertaScreen extends ConsumerWidget {
  const MiHuertaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final modeLabel = ref.watch(userModeProvider.notifier).modeLabel;
    final settings = ref.watch(settingsProvider);
    final esp32Conectado = user?.esp32Connected ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Mi Huerta')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.profundoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(child: Icon(Icons.water_drop_rounded, size: 40, color: AppColors.profundo)),
                ),
                SizedBox(height: 12),
                Text(settings.huertaNombre, style: TextStyle(
                  fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
                )),
                SizedBox(height: 4),
                Text('$modeLabel · ${settings.towerLabel} (${settings.towerCapacity} un.)', style: TextStyle(
                  fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
          SizedBox(height: 12),
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
                  leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Nombre de la huerta', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(settings.huertaNombre, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _editarNombre(context, ref, settings.huertaNombre),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.wifi, color: esp32Conectado ? AppColors.profundo : Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('ESP32 conectado', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(esp32Conectado ? 'Conectado' : 'No conectado', style: TextStyle(fontFamily: 'Inter', color: esp32Conectado ? AppColors.profundo : Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/conectar-esp32'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.straighten, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Capacidad', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('${settings.towerCapacity} plantas · ${settings.towerNiveles} niveles · ${settings.formatMeters(settings.towerAltura)}', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESPECIFICACIONES TÉCNICAS',
                  style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 12),
                _specRow(context, 'Modelo', settings.towerLabel),
                _specRow(context, 'Altura', settings.formatMeters(settings.towerAltura)),
                _specRow(context, 'Niveles', '${settings.towerNiveles}'),
                _specRow(context, 'Plantas máximas', '${settings.towerCapacity}'),
                _specRow(context, 'Reservorio', settings.formatVolume(settings.towerCapacity == 12 ? 18 : 35)),
                _specRow(context, 'Riego', 'Automático por gravedad'),
                _specRow(context, 'Material', 'PVC grado alimenticio'),
              ],
            ),
          ),
          SizedBox(height: 12),
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
                  leading: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Reiniciar ESP32', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('Reinicia el controlador sin perder configuración', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _reiniciarEsp32(context),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text('Restablecer configuración de fábrica', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.danger)),
                  onTap: () => _confirmarReset(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editarNombre(BuildContext context, WidgetRef ref, String actual) {
    final controller = TextEditingController(text: actual);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nombre de la huerta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Ej. Mi Huerta Viva'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                ref.read(settingsProvider.notifier).setHuertaNombre(nombre);
              }
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _reiniciarEsp32(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Text('Reiniciando ESP32...'),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ESP32 reiniciado correctamente'), duration: Duration(seconds: 2)),
        );
      }
    });
  }

  void _confirmarReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Restablecer huerta?'),
        content: Text('Se borrará la configuración local de tu huerta (nombre, preferencias). Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).resetAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Configuración restablecida'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: Text('Restablecer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _specRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
