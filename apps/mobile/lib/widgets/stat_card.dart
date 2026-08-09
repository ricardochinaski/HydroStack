import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String metric;
  final String label;
  final String? unit;
  final Color? accentColor;
  final double? progress;

  const StatCard({
    super.key,
    required this.icon,
    required this.metric,
    required this.label,
    this.unit,
    this.accentColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.profundo;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              SizedBox(width: 8),
              Text(label.toUpperCase(),
                style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(metric,
                style: AppTypography.metricStyle.copyWith(color: accent),
              ),
              if (unit != null) ...[
                SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Text(unit!,
                    style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
