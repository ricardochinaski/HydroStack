import 'package:flutter/material.dart';
import '../models/planta.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> items;

  const TimelineWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.profundo,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).cardColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.profundo.withValues(alpha: 0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Container(width: 2, height: 40, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ],
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.week.toUpperCase(),
                          style: AppTypography.techLabelSmall.copyWith(color: AppColors.profundo),
                        ),
                        SizedBox(height: 4),
                        Text(item.title, style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface,
                        )),
                        SizedBox(height: 2),
                        Text(item.desc, style: TextStyle(
                          fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
