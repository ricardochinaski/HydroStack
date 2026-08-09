enum SensorEstado { ok, warn, danger }

class LecturaSensor {
  final String id;
  final String sensorName;
  final String icon;
  final String unidad;
  final double valor;
  final double minOptimo;
  final double maxOptimo;
  final DateTime timestamp;
  final String? rango;

  const LecturaSensor({
    required this.id,
    required this.sensorName,
    required this.icon,
    required this.unidad,
    required this.valor,
    required this.minOptimo,
    required this.maxOptimo,
    required this.timestamp,
    this.rango,
  });

  SensorEstado get estado {
    if (valor < minOptimo * 0.8 || valor > maxOptimo * 1.2) {
      return SensorEstado.danger;
    }
    if (valor < minOptimo || valor > maxOptimo) {
      return SensorEstado.warn;
    }
    return SensorEstado.ok;
  }

  String get estadoLabel {
    switch (estado) {
      case SensorEstado.ok:
        return 'Bien';
      case SensorEstado.warn:
        return 'Atención';
      case SensorEstado.danger:
        return 'Peligro';
    }
  }
}
