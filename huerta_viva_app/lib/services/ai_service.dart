abstract class AIService {
  Future<String> diagnosticarPlanta(String imagePath, String plantaNombre);
}

class MockAIService implements AIService {
  final List<Map<String, String>> _diagnosticos = [
    {'sintoma': 'hojas amarillas', 'diagnostico': 'Parece deficiencia de nitrógeno. Agrega 5mL de nutriente A por litro de agua y revisa en 3 días.'},
    {'sintoma': 'hojas cafes', 'diagnostico': 'Podría ser exceso de sales (quemadura). Reduce la concentración de nutrientes al 75% y enjuaga con agua limpia.'},
    {'sintoma': 'hojas marchitas', 'diagnostico': 'Las hojas marchitas indican estrés hídrico o temperatura alta. Revisa el nivel de agua y mueve la torre a un lugar más fresco.'},
    {'sintoma': 'manchas blancas', 'diagnostico': 'Podría ser oídio (hongo). Aumenta la ventilación alrededor de la torre y reduce la humedad.'},
    {'sintoma': 'hojas enrolladas', 'diagnostico': 'Las hojas enrolladas pueden indicar estrés por calor o falta de riego. Revisa temperatura y programa riego más frecuente.'},
  ];

  @override
  Future<String> diagnosticarPlanta(String imagePath, String plantaNombre) async {
    await Future.delayed(const Duration(seconds: 2));
    final idx = DateTime.now().millisecondsSinceEpoch % _diagnosticos.length;
    final diag = _diagnosticos[idx];
    return '🔍 Diagnóstico para tu $plantaNombre\n\n${diag['diagnostico']}\n\nNivel de urgencia: ${idx == 0 ? "Alto" : idx < 3 ? "Medio" : "Bajo"}\n\n¿Necesitas más ayuda? Revisa la guía completa en la app.';
  }
}
