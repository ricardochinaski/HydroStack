class PlantaInfo {
  final String id;
  final String nombre;
  final String categoria;
  final String caracteristicas;
  final String propiedades;
  final List<String> vitaminas;
  final String phIdeal;
  final String ecIdeal;
  final String tiempoCosecha;

  const PlantaInfo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.caracteristicas,
    required this.propiedades,
    required this.vitaminas,
    required this.phIdeal,
    required this.ecIdeal,
    required this.tiempoCosecha,
  });
}
