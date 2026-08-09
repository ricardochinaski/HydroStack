class RegistroCosecha {
  final String id;
  final String plantaId;
  final String plantaNombre;
  final String emoji;
  final double gramos;
  final DateTime fecha;
  final String? nota;

  const RegistroCosecha({
    required this.id,
    required this.plantaId,
    required this.plantaNombre,
    required this.emoji,
    required this.gramos,
    required this.fecha,
    this.nota,
  });
}
