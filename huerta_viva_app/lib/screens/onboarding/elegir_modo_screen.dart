import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../services/storage_service.dart';

class ElegirModoScreen extends ConsumerWidget {
  const ElegirModoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu modelo de huerta',
                    style: TextStyle(
                      fontFamily: 'Montserrat', fontSize: 28, fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Selecciona el modelo que tienes. Define qué sensores y funciones están disponibles.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _ModoCard(
                    icon: modeIcon(AppMode.basic),
                    title: 'BASIC',
                    subtitle: 'SOLO CIRCULACIÓN',
                    desc: 'Sin sensores. Solo bomba circuladora para oxigenar y mover el agua.',
                    color: AppColors.circuit,
                    gradient: [AppColors.circuit.withValues(alpha: 0.18), AppColors.circuit.withValues(alpha: 0.06)],
                    onTap: () => _seleccionar(context, ref, AppMode.basic),
                  ),
                  SizedBox(height: 16),
                  _ModoCard(
                    icon: modeIcon(AppMode.eco),
                    title: 'ECO',
                    subtitle: 'SENSORES BÁSICOS',
                    desc: 'Sensores de pH, temperatura y nivel de agua. Sin dosificación de nutrientes.',
                    color: AppColors.eco,
                    gradient: [AppColors.eco.withValues(alpha: 0.18), AppColors.eco.withValues(alpha: 0.06)],
                    badge: 'POPULAR',
                    onTap: () => _seleccionar(context, ref, AppMode.eco),
                  ),
                  SizedBox(height: 16),
                  _ModoCard(
                    icon: modeIcon(AppMode.pro),
                    title: 'PRO',
                    subtitle: 'CONTROL TOTAL',
                    desc: 'Todos los sensores (incluye EC) + dosificación automática de nutrientes.',
                    color: AppColors.pro,
                    gradient: [AppColors.pro.withValues(alpha: 0.18), AppColors.pro.withValues(alpha: 0.06)],
                    onTap: () => _seleccionar(context, ref, AppMode.pro),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionar(BuildContext context, WidgetRef ref, AppMode mode) async {
    ref.read(userModeProvider.notifier).setMode(mode);
    final storage = SharedPrefsStorageService();
    await storage.setString('app_mode', mode.name);
    // Persiste el modelo en el perfil del usuario (Firestore si está activo).
    final uid = ref.read(authProvider).valueOrNull?.uid;
    if (uid != null) {
      await ref.read(firestoreServiceProvider).saveUserMode(uid, mode.name);
    }
    if (context.mounted) context.go('/conectar-esp32');
  }
}

class _ModoCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, desc;
  final String? badge;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModoCard({
    required this.icon, required this.title, required this.subtitle,
    required this.desc, required this.color, required this.gradient,
    required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Icon(icon, size: 30, color: color)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: TextStyle(
                          fontFamily: 'Montserrat', fontSize: 19, fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2,
                        )),
                        if (badge != null) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(badge!,
                              style: TextStyle(
                                fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w700,
                                color: color, letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.techLabelSmall.copyWith(color: color.withValues(alpha: 0.8))),
                    SizedBox(height: 6),
                    Text(desc, style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35,
                    )),
                  ],
                ),
              ),
              SizedBox(width: 4),
              Container(
                margin: EdgeInsets.only(top: 4),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
