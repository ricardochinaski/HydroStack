import 'package:flutter/material.dart';
import '../models/planta.dart';
import '../theme/typography.dart';
import '../utils/icon_assets.dart';

class PlantaTile extends StatelessWidget {
  final Planta planta;
  final VoidCallback? onTap;

  const PlantaTile({super.key, required this.planta, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
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
          children: [
            plantaIcon(planta.id, size: 44),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planta.name, style: TextStyle(
                    fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
                  )),
                  SizedBox(height: 2),
                  Text(planta.latin, style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic,
                  )),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      _tag(context, planta.diffLabel, planta.difficulty),
                      SizedBox(width: 8),
                      Text('pH ${planta.params.ph}  EC ${planta.params.ec}',
                        style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String label, String difficulty) {
    Color color;
    Color bg;
    switch (difficulty) {
      case 'facil':
        color = Color(0xFF065F46);
        bg = Color(0xFFD1FAE5);
        break;
      case 'medio':
        color = Color(0xFF92400E);
        bg = Color(0xFFFEF3C7);
        break;
      default:
        color = Color(0xFF991B1B);
        bg = Color(0xFFFEE2E2);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(),
        style: AppTypography.techLabelSmall.copyWith(color: color),
      ),
    );
  }
}
