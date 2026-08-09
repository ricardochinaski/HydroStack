import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class NotifMock extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final IconData icon;

  const NotifMock({
    super.key,
    required this.title,
    required this.body,
    this.time = 'AHORA',
    this.icon = Icons.eco_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.profundo,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Icon(icon, size: 16, color: Colors.white)),
              ),
              SizedBox(width: 10),
              Text('HIDROSMART',
                style: AppTypography.techLabel.copyWith(color: Colors.white54),
              ),
              Spacer(),
              Text(time,
                style: AppTypography.techLabelSmall.copyWith(color: Colors.white38),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(title, style: TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          SizedBox(height: 4),
          Text(body, style: TextStyle(
            fontFamily: 'Inter', fontSize: 12, color: Colors.white60,
          )),
        ],
      ),
    );
  }
}
