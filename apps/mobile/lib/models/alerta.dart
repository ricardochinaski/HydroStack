enum Prioridad { urgente, atencion, info }

class Alerta {
  final String id;
  final String icon;
  final String titulo;
  final String descripcion;
  final Prioridad prioridad;
  final DateTime fecha;
  final bool resuelta;
  final String? accionLabel;

  const Alerta({
    required this.id,
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.fecha,
    this.resuelta = false,
    this.accionLabel,
  });

  Alerta copyWith({bool? resuelta}) {
    return Alerta(
      id: id,
      icon: icon,
      titulo: titulo,
      descripcion: descripcion,
      prioridad: prioridad,
      fecha: fecha,
      resuelta: resuelta ?? this.resuelta,
      accionLabel: accionLabel,
    );
  }
}
