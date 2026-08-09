import 'package:flutter/material.dart';
import '../theme/typography.dart';

class NutrientBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text('$value%', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
