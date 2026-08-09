/// Datos de la "Guía de cultivo hidropónico en torre vertical de 24 unidades".
/// Conocimiento a nivel sistema (no por planta): parámetros del depósito,
/// programación de riego, calendario de cultivos, distribución y cuidados.
library;

class TorreParam {
  final String parametro;
  final String valor;
  final String nota;
  const TorreParam(this.parametro, this.valor, this.nota);
}

class CicloRiego {
  final String periodo;
  final String horario;
  final String detalle;
  const CicloRiego(this.periodo, this.horario, this.detalle);
}

class CultivoCalendario {
  final String cultivo;
  final String germinacion; // días
  final String trasplante;
  final String cosecha;
  final String ph;
  final String ec;
  const CultivoCalendario(this.cultivo, this.germinacion, this.trasplante, this.cosecha, this.ph, this.ec);
}

class ZonaTorre {
  final String zona;
  final String posiciones;
  final List<String> cultivos;
  const ZonaTorre(this.zona, this.posiciones, this.cultivos);
}

class CuidadoItem {
  final String titulo;
  final String detalle;
  const CuidadoItem(this.titulo, this.detalle);
}

class GuiaCultivoData {
  GuiaCultivoData._();

  static const String descripcion =
      'Torre vertical hidropónica de 24 posiciones, depósito de 20–40 L, bomba '
      'sumergible y recirculación tipo NFT/tower en ciclos programados. Un solo '
      'depósito para todas las plantas, por lo que se trabaja con parámetros '
      'intermedios de pH y EC que funcionan bien para hojas, hierbas y frutales ligeros.';

  // -- Parámetros objetivo de la torre mixta --
  static const List<TorreParam> parametros = [
    TorreParam('pH objetivo', '5.8 – 6.2', 'Ajustar con pH Up / Down comercial.'),
    TorreParam('EC objetivo', '1.6 – 2.0 mS/cm', 'Ajustar con nutrientes A + B.'),
    TorreParam('Temp. del agua', '18 – 22 °C', 'Hasta 24–25 °C máx. para frutales.'),
    TorreParam('Medición pH/EC', '1–2 veces al día', 'Rellenar con agua sola al nivel marcado.'),
    TorreParam('Cambio de solución', 'Cada 7 – 14 días', 'Renovar la solución completa.'),
  ];

  // -- Programación de riego (bomba) --
  static const List<CicloRiego> riego = [
    CicloRiego('Día (luz, ~14–16 h)', '15 ON / 45 OFF', 'Bomba encendida 15 min cada hora.'),
    CicloRiego('Noche (~8–10 h)', '15 ON / 105 OFF', 'Bomba 15 min cada 2–3 horas.'),
  ];

  static const String riegoNota =
      'Tras añadir nutrientes, dejar la bomba 15 min para homogeneizar antes de medir EC/pH. '
      'Ajustar tiempos si las raíces se ven muy secas o saturadas.';

  // -- Calendario por cultivo --
  static const List<CultivoCalendario> calendario = [
    CultivoCalendario('Lechuga', '3–7', 'día 10–14', '30–45 días', '5.5–6.5', '0.8–1.8'),
    CultivoCalendario('Espinaca', '5–10', 'día 10–14', '21–42 días', '5.5–6.5', '1.0–1.6'),
    CultivoCalendario('Acelga', '5–7', 'día 14–21', '35–60 días', '5.5–6.5', '1.2–2.0'),
    CultivoCalendario('Rúcula', '2–4', 'día 10–14', '21–35 días', '5.5–6.5', '0.8–1.2'),
    CultivoCalendario('Kale', '4–7', 'día 14–21', '28–35 días', '5.5–6.5', '1.5–2.5'),
    CultivoCalendario('Albahaca', '5–10', 'día 14–21', '21–35 días', '5.5–6.5', '1.0–1.6'),
    CultivoCalendario('Cilantro', '7–10', 'día 14–20', '30–45 días', '5.8–6.3', '1.0–1.6'),
    CultivoCalendario('Perejil', '10–21', 'día 21–28', '40–60 días', '5.5–6.5', '0.8–2.2'),
    CultivoCalendario('Menta', '7–14', 'día 14–21', '~30 días', '5.5–6.5', '1.2–1.6'),
    CultivoCalendario('Fresa', '—', 'plantín', '60–90 días', '5.5–6.0', '1.0–1.8'),
    CultivoCalendario('Tomate cherry', '7–10', 'plantín 12–16 cm', '60–80 días', '5.8–6.2', '1.8–2.0'),
    CultivoCalendario('Pepino', '5–10', 'día 14–21', '60–90 días', '5.8–6.5', '1.8–3.0'),
  ];

  // -- Distribución sugerida en la torre de 24 --
  static const List<ZonaTorre> distribucion = [
    ZonaTorre('Zona superior', '8 posiciones', ['2 fresa', '1 tomate cherry', '1 pepino', '2 kale', '2 acelga']),
    ZonaTorre('Zona central', '8 posiciones', ['4 lechuga', '2 espinaca', '2 rúcula']),
    ZonaTorre('Zona inferior', '8 posiciones', ['2 albahaca', '2 cilantro', '2 perejil', '2 menta']),
  ];

  static const String distribucionNota =
      'Con pH ~6.0 y EC 1.6–2.0 mS/cm todas las especies quedan dentro o cerca de su rango. '
      'Los frutales van en posiciones altas/medias con más luz; hojas y hierbas en el resto.';

  // -- Cuidados generales --
  static const List<CuidadoItem> cuidados = [
    CuidadoItem('Luz', 'Hojas y hierbas: 12–16 h/día. Frutales: 14–16 h de luz intensa.'),
    CuidadoItem('Temperatura ambiente', 'Espinaca/rúcula 15–21 °C · Fresa 18–24 °C · Tomate/pepino día 22–28 °C, noche 16–20 °C.'),
    CuidadoItem('Higiene', 'Limpiar depósito, bomba y líneas cada 1–2 meses. Retirar raíces que bloqueen canales.'),
    CuidadoItem('Plagas', 'Vigilar pulgones, mosca blanca y trips. Priorizar control biológico.'),
    CuidadoItem('Cosecha "cut and come again"', 'Cortar hojas exteriores y dejar el corazón: permite cosechas repetidas durante semanas.'),
  ];
}
