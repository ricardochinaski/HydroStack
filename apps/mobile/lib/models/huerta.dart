class PlantaInstalada {
  final String plantaId;
  final int nivel;
  final DateTime fechaPlantacion;
  final bool activa;

  const PlantaInstalada({
    required this.plantaId,
    required this.nivel,
    required this.fechaPlantacion,
    this.activa = true,
  });
}

class Huerta {
  final String id;
  final String nombre;
  final List<PlantaInstalada> plantas;
  final int capacidadMaxima;
  final bool esp32Connected;
  final String? esp32Id;

  const Huerta({
    required this.id,
    this.nombre = 'Mi Huerta',
    this.plantas = const [],
    this.capacidadMaxima = 24,
    this.esp32Connected = false,
    this.esp32Id,
  });

  int get plantasActivas => plantas.where((p) => p.activa).length;

  Huerta copyWith({
    String? id,
    String? nombre,
    List<PlantaInstalada>? plantas,
    int? capacidadMaxima,
    bool? esp32Connected,
    String? esp32Id,
  }) {
    return Huerta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      plantas: plantas ?? this.plantas,
      capacidadMaxima: capacidadMaxima ?? this.capacidadMaxima,
      esp32Connected: esp32Connected ?? this.esp32Connected,
      esp32Id: esp32Id ?? this.esp32Id,
    );
  }
}
