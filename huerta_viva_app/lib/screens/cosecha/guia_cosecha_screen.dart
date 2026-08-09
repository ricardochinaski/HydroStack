import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class GuiaCosechaScreen extends StatelessWidget {
  const GuiaCosechaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Guía de Cosecha')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Center(child: Icon(Icons.content_cut_rounded, size: 56, color: AppColors.profundo)),
          SizedBox(height: 12),
          Center(child: Text('Albahaca',
            style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
          )),
          SizedBox(height: 20),
          ..._pasos.map((p) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.profundoBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(child: Text(p['num']!, style: TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.w800, color: AppColors.profundo, fontSize: 12,
                  ))),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['title']!, style: TextStyle(
                        fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface,
                      )),
                      SizedBox(height: 4),
                      Text(p['desc']!, style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          )),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.profundoBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: AppColors.circuit),
                SizedBox(width: 10),
                Expanded(
                  child: Text('La planta sigue produciendo por meses si cosechas correctamente. Nunca cortes más del 30%.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final _pasos = [
    {'num': '1', 'title': 'Corta sobre las hojas más bajas', 'desc': 'Busca el punto justo encima de un par de hojas grandes y corta el tallo principal.'},
    {'num': '2', 'title': 'No cortes más del 30%', 'desc': 'Deja suficientes hojas para que la planta siga haciendo fotosíntesis y produzca nuevos brotes.'},
    {'num': '3', 'title': 'Corta por encima de un par de hojas', 'desc': 'Siempre deja al menos 2 pares de hojas en la planta para que pueda regenerarse.'},
    {'num': '4', 'title': 'Pinza la punta para ramificar', 'desc': 'Si cortas la punta principal, la planta desarrollará ramas laterales y será más frondosa.'},
  ];
}
