import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/alerta.dart';
import '../../providers/notif_prefs_provider.dart';
import '../../providers/alertas_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/colors.dart';

class NotifPrefsScreen extends ConsumerWidget {
  const NotifPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notifPrefsProvider);
    final notifier = ref.read(notifPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Controla qué notificaciones quieres recibir',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _toggle(context, Icons.water_drop_outlined, 'Agua baja', 'Siempre activo, no se puede apagar', prefs.aguaBaja, null),
          _toggle(context, Icons.content_cut, 'Hora de cosechar', 'Cuando una planta está lista', prefs.cosecha, notifier.setCosecha),
          _toggle(context, Icons.eco_outlined, 'Cambio de agua', 'Cada 2 semanas', prefs.cambioAgua, notifier.setCambioAgua),
          _toggle(context, Icons.bar_chart_rounded, 'Resumen diario', 'Estado general cada mañana', prefs.resumenDiario, notifier.setResumenDiario),
          _toggle(context, Icons.science_outlined, 'Alertas de pH', 'pH fuera del rango ideal', prefs.alertasPH, notifier.setAlertasPH),
          _toggle(context, Icons.thermostat_rounded, 'Temperatura extrema', 'Cuando hace mucho calor o frío', prefs.temperatura, notifier.setTemperatura),
          const SizedBox(height: 16),
          Text('HORARIO',
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 1, color: AppColors.gris),
          ),
          const SizedBox(height: 8),
          _toggle(context, Icons.bedtime_outlined, 'Horario silencioso', '22:00 – 07:00 · sin notificaciones', prefs.horarioSilencioso, notifier.setHorarioSilencioso),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.circuitBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppColors.circuit),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('La alerta de agua baja no se puede desactivar por seguridad de tus plantas.',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.carbon, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _probar(context, ref),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Probar notificación'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/notificaciones'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver ejemplos de notificaciones'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _probar(BuildContext context, WidgetRef ref) async {
    // Notificación del sistema (en Android/iOS) + alerta en la app.
    await ref.read(notificationServiceProvider).showLocalNotification(
      title: 'Notificación de prueba 🌿',
      body: 'Tu sistema de notificaciones HidroSmart está funcionando.',
    );
    ref.read(alertasProvider.notifier).addAlerta(Alerta(
      id: 'prueba',
      icon: '🔔',
      titulo: 'Notificación de prueba',
      descripcion: 'Esta es una alerta de prueba generada desde Ajustes.',
      prioridad: Prioridad.info,
      fecha: DateTime.now(),
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación enviada. Revisa la campana de alertas.'), duration: Duration(seconds: 2)),
      );
    }
  }

  Widget _toggle(BuildContext context, IconData icon, String title, String subtitle, bool value, void Function(bool)? onChanged) {
    final locked = onChanged == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: locked ? AppColors.gris : AppColors.profundo),
        title: Text(title, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        value: value,
        activeThumbColor: AppColors.profundo,
        onChanged: onChanged,
      ),
    );
  }
}
