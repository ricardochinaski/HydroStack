import 'package:flutter/material.dart';

final Map<String, String> _plantaMap = {
  'acelga': 'Acelga.png',
  'albahaca': 'Albahaca.png',
  'cilantro': 'Cilantro.png',
  'espinaca': 'Espinaca.png',
  'fresa': 'Frutilla.png',
  'kale': 'Kale.png',
  'lechuga': 'Lechuga.png',
  'menta': 'Menta.png',
  'pepino': 'Pepino.png',
  'perejil': 'Perejil.png',
  'rucula': 'Rucula.png',
  'tomate-cherry': 'tomate_cherry.png',
  'tomate_cherry': 'tomate_cherry.png',
};

String _plantaAssetPath(String id) {
  final file = _plantaMap[id];
  if (file == null) return '';
  return 'assets/images/icon_plant/$file';
}

Widget plantaIcon(String id, {double size = 32}) {
  final path = _plantaAssetPath(id);
  if (path.isEmpty) return const SizedBox.shrink();
  return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
}

final Map<String, String> _sensorMap = {
  'Temperatura ambiente': 'temperatura_ambiente.png',
  'Humedad ambiente': 'humedad_ambiente.png',
  'Temperatura agua': 'temperatura_agua.png',
  'Nivel agua': 'nivel_agua.png',
  'pH agua': 'ph_agua.png',
  'EC nutrientes': 'ec.png',
};

String sensorAssetPath(String sensorName) {
  final file = _sensorMap[sensorName];
  if (file == null) return '';
  return 'assets/images/icon_parametros/$file';
}

Widget sensorIcon(String sensorName, {double size = 22}) {
  final path = sensorAssetPath(sensorName);
  if (path.isEmpty) return const SizedBox.shrink();
  return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
}

/// Traduce los emojis usados en datos (alertas, notificaciones, cosechas)
/// a iconos vectoriales de Material. Fallback: icono genérico de hoja.
IconData iconFromEmoji(String emoji) {
  switch (emoji.trim()) {
    case '💧':
      return Icons.water_drop_rounded;
    case '🌱':
      return Icons.eco_rounded;
    case '🌿':
      return Icons.local_florist_rounded;
    case '🎉':
      return Icons.celebration_rounded;
    case '✅':
      return Icons.check_circle_rounded;
    case '🧠':
      return Icons.psychology_rounded;
    case '⚡':
      return Icons.bolt_rounded;
    case '🌡️':
    case '🌡':
      return Icons.thermostat_rounded;
    case '⚗️':
      return Icons.science_outlined;
    case '✂️':
      return Icons.content_cut_rounded;
    case '📊':
      return Icons.bar_chart_rounded;
    case '🔔':
      return Icons.notifications_rounded;
    case '⚠️':
      return Icons.warning_amber_rounded;
    default:
      return Icons.eco_rounded;
  }
}
