import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  String t(String es, String en, String pt) {
    switch (locale) {
      case 'English':
        return en;
      case 'Português':
        return pt;
      default:
        return es;
    }
  }

  // Navigation
  String get navInicio => t('Inicio', 'Home', 'Início');
  String get navPlantas => t('Plantas', 'Plants', 'Plantas');
  String get navControl => t('Control', 'Control', 'Controle');
  String get navCosecha => t('Cosecha', 'Harvest', 'Colheita');
  String get navAjustes => t('Ajustes', 'Settings', 'Configurações');

  // Perfil
  String get miPerfil => t('Mi Perfil', 'My Profile', 'Meu Perfil');
  String get modoActivo => t('Modo activo', 'Active mode', 'Modo ativo');
  String get notificaciones => t('Notificaciones', 'Notifications', 'Notificações');
  String get miHuerta => t('Mi Huerta', 'My Garden', 'Minha Horta');
  String get upgradeAPro => t('Upgrade a PRO', 'Upgrade to PRO', 'Upgrade para PRO');
  String get exportarDatos => t('Exportar datos', 'Export data', 'Exportar dados');
  String get tema => t('Tema', 'Theme', 'Tema');
  String get idioma => t('Idioma', 'Language', 'Idioma');
  String get unidades => t('Unidades', 'Units', 'Unidades');
  String get centroAyuda => t('Centro de ayuda', 'Help Center', 'Central de Ajuda');
  String get privacidadDatos => t('Privacidad y datos', 'Privacy & data', 'Privacidade e dados');
  String get acercaDe => t('Acerca de HidroSmart', 'About HidroSmart', 'Sobre o HidroSmart');
  String get cerrarSesion => t('Cerrar sesión', 'Log out', 'Sair');

  // Home
  String get tuHuertaPerfecta => t('Tu huerta está perfecta', 'Your garden is perfect', 'Sua horta está perfeita');
  String get verMisPlantas => t('Ver mis plantas', 'View my plants', 'Ver minhas plantas');
  String get resumenDeTuHuerta => t('Resumen de tu huerta', 'Garden summary', 'Resumo da sua horta');
  String get regarAhora => t('Regar ahora', 'Water now', 'Regar agora');
  String get dashboardEnVivo => t('Dashboard en vivo', 'Live dashboard', 'Painel em tempo real');

  // Temas
  String get claro => t('Claro', 'Light', 'Claro');
  String get oscuro => t('Oscuro', 'Dark', 'Escuro');
  String get automatico => t('Automático (según el sistema)', 'Automatic (system)', 'Automático (sistema)');

  String forThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return claro;
      case ThemeMode.dark: return oscuro;
      case ThemeMode.system: return automatico;
    }
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final idioma = ref.watch(settingsProvider).idioma;
  return AppStrings(idioma);
});
