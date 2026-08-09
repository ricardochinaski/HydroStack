import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/plantas') || path.startsWith('/diagnostico')) return 1;
    if (path.startsWith('/panel-sensores') || path.startsWith('/riego') || path.startsWith('/programar') || path.startsWith('/nutrientes')) return 2;
    if (path.startsWith('/cosecha') || path.startsWith('/guia-cosecha') || path.startsWith('/guia-cultivo') || path.startsWith('/historial')) return 3;
    if (path.startsWith('/perfil') || path.startsWith('/notif') || path.startsWith('/cambiar') || path.startsWith('/mi-huerta') || path.startsWith('/ayuda') || path.startsWith('/privacidad') || path.startsWith('/acerca')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/plantas');
              case 2: context.go('/panel-sensores');
              case 3: context.go('/cosecha-lista');
              case 4: context.go('/perfil');
            }
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: s.navInicio),
            BottomNavigationBarItem(icon: const Icon(Icons.eco_outlined), activeIcon: const Icon(Icons.eco), label: s.navPlantas),
            BottomNavigationBarItem(icon: const Icon(Icons.sensors_outlined), activeIcon: const Icon(Icons.sensors), label: s.navControl),
            BottomNavigationBarItem(icon: const Icon(Icons.content_cut_outlined), activeIcon: const Icon(Icons.content_cut), label: s.navCosecha),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: s.navAjustes),
          ],
        ),
      ),
    );
  }
}
