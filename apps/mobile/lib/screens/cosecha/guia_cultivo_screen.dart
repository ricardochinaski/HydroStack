import 'package:flutter/material.dart';
import '../../data/guia_cultivo_data.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class GuiaCultivoScreen extends StatelessWidget {
  const GuiaCultivoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Guía de Cultivo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.profundoBg, AppColors.circuitBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.menu_book_rounded, color: AppColors.profundo, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Torre vertical de 24 unidades',
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.carbon),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(GuiaCultivoData.descripcion,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: AppColors.carbon, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Parámetros de la torre
          _seccion(context, Icons.tune_rounded, 'Parámetros del depósito'),
          _card(context, child: Column(
            children: [
              for (final p in GuiaCultivoData.parametros) ...[
                if (p != GuiaCultivoData.parametros.first) Divider(height: 18, color: Theme.of(context).dividerColor),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.parametro, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(p.nota, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(p.valor, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.profundo)),
                  ],
                ),
              ],
            ],
          )),
          const SizedBox(height: 20),

          // Programación de riego
          _seccion(context, Icons.schedule_rounded, 'Programación de riego'),
          for (final c in GuiaCultivoData.riego) ...[
            _card(context, child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.circuitBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.water_drop_rounded, color: AppColors.circuit, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.periodo, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      Text(c.detalle, style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.circuitBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(c.horario, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.circuit)),
                ),
              ],
            )),
            const SizedBox(height: 10),
          ],
          _nota(context, GuiaCultivoData.riegoNota),
          const SizedBox(height: 20),

          // Calendario de cultivos
          _seccion(context, Icons.calendar_month_rounded, 'Calendario de cultivos'),
          _card(context, padding: const EdgeInsets.all(10), child: _calendario(context)),
          const SizedBox(height: 20),

          // Distribución en la torre
          _seccion(context, Icons.view_column_rounded, 'Distribución en la torre (24)'),
          for (final z in GuiaCultivoData.distribucion) ...[
            _card(context, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(z.zona, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                  const Spacer(),
                  Text(z.posiciones, style: AppTypography.techLabelSmall.copyWith(color: AppColors.profundo)),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    for (final cult in z.cultivos)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.profundoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cult, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.profundo)),
                      ),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 10),
          ],
          _nota(context, GuiaCultivoData.distribucionNota),
          const SizedBox(height: 20),

          // Cuidados generales
          _seccion(context, Icons.spa_rounded, 'Cuidados generales'),
          _card(context, child: Column(
            children: [
              for (final c in GuiaCultivoData.cuidados) ...[
                if (c != GuiaCultivoData.cuidados.first) Divider(height: 18, color: Theme.of(context).dividerColor),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.profundo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.titulo, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(c.detalle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _seccion(BuildContext context, IconData icon, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.profundo),
        const SizedBox(width: 8),
        Text(titulo, style: TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  Widget _card(BuildContext context, {required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _nota(BuildContext context, String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.circuitBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: AppColors.circuit),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.carbon, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _calendario(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    TextStyle head = AppTypography.techLabelSmall.copyWith(color: onVar);
    TextStyle cell(Color c, [bool bold = false]) => TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: c);

    Widget row(List<Widget> cells, {bool header = false}) {
      return Container(
        decoration: header ? null : BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            Expanded(flex: 24, child: cells[0]),
            Expanded(flex: 16, child: cells[1]),
            Expanded(flex: 22, child: cells[2]),
            Expanded(flex: 18, child: cells[3]),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(header: true, [
          Text('CULTIVO', style: head),
          Text('GERM.', style: head),
          Text('COSECHA', style: head),
          Text('EC', style: head),
        ]),
        for (final c in GuiaCultivoData.calendario)
          row([
            Text(c.cultivo, style: cell(onSurf, true)),
            Text('${c.germinacion} d', style: cell(onVar)),
            Text(c.cosecha, style: cell(onVar)),
            Text(c.ec, style: cell(AppColors.profundo, true)),
          ]),
      ],
    );
  }
}
