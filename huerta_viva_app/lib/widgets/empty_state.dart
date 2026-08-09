import 'package:flutter/material.dart';
import '../theme/colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.eco_rounded,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gris),
            SizedBox(height: 20),
            Text(title, style: TextStyle(
              fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
            ), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
              ), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
