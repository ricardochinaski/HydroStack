import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';

class CambiarModoScreen extends ConsumerWidget {
  const CambiarModoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Cambiar Modo')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Tu modelo define qué sensores y funciones están disponibles.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 20),
          _modoOption(context, ref, AppMode.basic, 'BASIC', 'Sin sensores. Solo bomba circuladora.', currentMode, AppColors.circuit, AppColors.circuitBg),
          SizedBox(height: 10),
          _modoOption(context, ref, AppMode.eco, 'ECO', 'Sensores de pH, temperatura y nivel. Sin dosificación.', currentMode, AppColors.eco, AppColors.ecoBg),
          SizedBox(height: 10),
          _modoOption(context, ref, AppMode.pro, 'PRO', 'Todos los sensores + dosificación automática de nutrientes.', currentMode, AppColors.pro, AppColors.proBg),
        ],
      ),
    );
  }

  Widget _modoOption(BuildContext context, WidgetRef ref, AppMode mode, String title, String desc, AppMode current, Color color, Color bgColor) {
    final active = current == mode;
    return GestureDetector(
      onTap: () {
        ref.read(userModeProvider.notifier).setMode(mode);
        final uid = ref.read(authProvider).valueOrNull?.uid;
        if (uid != null) {
          ref.read(firestoreServiceProvider).saveUserMode(uid, mode.name);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo $title activado'), duration: Duration(seconds: 1)),
        );
        context.go('/home');
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : Theme.of(context).dividerColor, width: active ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: active ? bgColor : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(modeIcon(mode), size: 24, color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700,
                    color: active ? color : Theme.of(context).colorScheme.onSurface,
                  )),
                  SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
