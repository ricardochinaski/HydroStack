import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  static final _faqs = [
    ('¿Cómo conecto mi ESP32?', 'Ve a Mi Huerta → ESP32 conectado, o desde el onboarding inicial. Asegúrate de que el dispositivo esté encendido y dentro del rango Bluetooth.'),
    ('¿Qué diferencia hay entre los modos ECO, AUTÓNOMO y PRO?', 'ECO opera de forma simple y segura. AUTÓNOMO toma decisiones por sí mismo. PRO te da control total con datos en tiempo real y ajuste de parámetros.'),
    ('¿Cada cuánto debo cambiar el agua?', 'Recomendamos cada 2 semanas. Puedes activar un recordatorio en Notificaciones.'),
    ('¿Por qué no puedo desactivar la alerta de agua baja?', 'Es una medida de seguridad para evitar que tus plantas se dañen por falta de agua.'),
    ('¿Cómo cambio de modo?', 'Ve a Ajustes → Modo activo y selecciona el que prefieras. Puedes cambiarlo cuando quieras.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Centro de ayuda')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Preguntas frecuentes',
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(height: 12),
          ..._faqs.map((faq) => Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(side: BorderSide.none),
              title: Text(faq.$1, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
              childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(faq.$2, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                ),
              ],
            ),
          )),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.profundoBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.profundo),
                SizedBox(width: 12),
                Expanded(
                  child: Text('¿No encontraste lo que buscabas? Escríbenos a soporte@hidrosmart.app',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
