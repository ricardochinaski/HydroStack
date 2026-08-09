import 'package:flutter/material.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  static final _secciones = [
    ('Qué datos recopilamos', 'Recopilamos las lecturas de tus sensores (pH, temperatura, nivel de agua), tu correo y nombre de cuenta, y las plantas que registras en tu huerta.'),
    ('Cómo usamos tus datos', 'Usamos tus datos únicamente para mostrar el estado de tu huerta, generar alertas y mejorar las recomendaciones de cuidado.'),
    ('Con quién compartimos datos', 'No vendemos ni compartimos tus datos con terceros. Solo se almacenan en tu cuenta y en el dispositivo ESP32 conectado.'),
    ('Tus derechos', 'Puedes exportar o eliminar tus datos en cualquier momento desde Ajustes → Exportar datos o Restablecer configuración.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Privacidad y datos')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _secciones.expand((s) => [
                Text(s.$1, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text(s.$2, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                SizedBox(height: 16),
              ]).toList()..removeLast(),
            ),
          ),
          SizedBox(height: 16),
          Text('Última actualización: junio 2026',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
