import 'package:flutter/material.dart';
import '../models/alerta.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/icon_assets.dart';

class AlertCard extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback? onResolve;

  const AlertCard({super.key, required this.alerta, this.onResolve});

  Color _accentColor() {
    switch (alerta.prioridad) {
      case Prioridad.urgente: return AppColors.danger;
      case Prioridad.atencion: return AppColors.warning;
      case Prioridad.info: return AppColors.info;
    }
  }

  Color _accentBg() {
    switch (alerta.prioridad) {
      case Prioridad.urgente: return AppColors.dangerBg;
      case Prioridad.atencion: return AppColors.warnBg;
      case Prioridad.info: return AppColors.infoBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final bg = _accentBg();

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alerta.resuelta ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alerta.resuelta ? Theme.of(context).dividerColor : accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: alerta.resuelta ? Theme.of(context).colorScheme.surfaceContainerHighest : bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(iconFromEmoji(alerta.icon), size: 18, color: alerta.resuelta ? Theme.of(context).colorScheme.onSurfaceVariant : accent)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alerta.titulo, style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: alerta.resuelta ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                )),
                SizedBox(height: 2),
                Text(alerta.descripcion, style: TextStyle(
                  fontFamily: 'Inter', fontSize: 11,
                  color: alerta.resuelta ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
                )),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                      child: Text(alerta.prioridad.name.toUpperCase(),
                        style: AppTypography.techLabelSmall.copyWith(color: accent),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(_formatDate(alerta.fecha),
                      style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    if (!alerta.resuelta && onResolve != null) ...[
                      Spacer(),
                      GestureDetector(
                        onTap: onResolve,
                        child: Text('RESOLVER',
                          style: AppTypography.techLabel.copyWith(color: AppColors.profundo),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} MIN';
    if (diff.inHours < 24) return 'hace ${diff.inHours}H';
    return 'hace ${diff.inDays}D';
  }
}
