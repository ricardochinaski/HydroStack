import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_strings.dart';
import '../../theme/colors.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final modeNotifier = ref.read(userModeProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(s.miPerfil)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          userAsync.when(
            data: (user) => Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.profundoBg,
                    child: Icon(Icons.water_drop_rounded, size: 30, color: AppColors.profundo),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Usuario', style: TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18, color: Theme.of(context).colorScheme.onSurface,
                        )),
                        Text(user?.email ?? '', style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error')),
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
                  leading: Icon(modeIcon(ref.watch(userModeProvider)), color: AppColors.profundo),
                  title: Text(s.modoActivo, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(modeNotifier.modeLabel, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/cambiar-modo'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: AppColors.profundo),
                  title: Text(s.notificaciones, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/notif-prefs'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.local_florist_outlined, color: AppColors.profundo),
                  title: Text(s.miHuerta, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(modeNotifier.modeLabel, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/mi-huerta'),
                ),
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
                  leading: Icon(Icons.star_border, color: AppColors.profundo),
                  title: Text(s.upgradeAPro, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('Sensores pH, EC y dosificación', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Chip(
                    label: Text('\$450', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: AppColors.proBg,
                    side: BorderSide.none,
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => _confirmarUpgrade(context, ref),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.exportarDatos, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () => _exportarDatos(context, s),
                ),
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
                  leading: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.tema, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(s.forThemeMode(settings.themeMode), style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _elegirTema(context, settingsNotifier, settings.themeMode, s),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.idioma, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(settings.idioma, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _elegirIdioma(context, settingsNotifier, settings.idioma, s),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.straighten_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.unidades, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text(settings.unidadesLabel, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => _elegirUnidades(context, settingsNotifier, settings.unidades, s),
                ),
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
                  leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.centroAyuda, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/ayuda'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.privacidadDatos, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/privacidad'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(s.acercaDe, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('Versión 1.0.0', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/acerca'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.developer_board_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text('Simulador ESP32 (dev)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('Telemetría en vivo del controlador', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push('/simulador'),
                ),
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
            child: ListTile(
              leading: Icon(Icons.logout, color: AppColors.danger),
              title: Text(s.cerrarSesion, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              onTap: () => _confirmarCerrarSesion(context, ref, s),
            ),
          ),
        ],
      ),
    );
  }

  void _elegirTema(BuildContext context, SettingsNotifier notifier, ThemeMode current, AppStrings s) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(s.tema, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            RadioGroup<ThemeMode>(
              groupValue: current,
              onChanged: (v) { notifier.setThemeMode(v!); Navigator.pop(context); },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(title: Text(s.claro), value: ThemeMode.light),
                  RadioListTile<ThemeMode>(title: Text(s.oscuro), value: ThemeMode.dark),
                  RadioListTile<ThemeMode>(title: Text(s.automatico), value: ThemeMode.system),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _elegirIdioma(BuildContext context, SettingsNotifier notifier, String current, AppStrings s) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(s.idioma, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            RadioGroup<String>(
              groupValue: current,
              onChanged: (v) { notifier.setIdioma(v!); Navigator.pop(context); },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final idioma in ['Español', 'English', 'Português'])
                    RadioListTile<String>(title: Text(idioma), value: idioma),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _elegirUnidades(BuildContext context, SettingsNotifier notifier, AppUnidades current, AppStrings s) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(s.unidades, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            RadioGroup<AppUnidades>(
              groupValue: current,
              onChanged: (v) { notifier.setUnidades(v!); Navigator.pop(context); },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AppUnidades>(title: Text('Métrico — °C · Litros · cm'), value: AppUnidades.metrico),
                  RadioListTile<AppUnidades>(title: Text('Imperial — °F · Galones · in'), value: AppUnidades.imperial),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarUpgrade(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Upgrade a PRO'),
        content: Text('Activa el modo PRO con sensores pH, EC y dosificación automática por \$450.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(userModeProvider.notifier).setMode(AppMode.pro);
              Navigator.pop(context);
              context.go('/home');
            },
            child: Text('Activar PRO'),
          ),
        ],
      ),
    );
  }

  void _exportarDatos(BuildContext context, AppStrings s) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Text('Exportando datos...'),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos exportados: huertaviva_export.csv'), duration: Duration(seconds: 2)),
        );
      }
    });
  }

  void _confirmarCerrarSesion(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Cerrar sesión?'),
        content: Text('Tendrás que volver a iniciar sesión para acceder a tu huerta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Text(s.cerrarSesion, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
