import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alertas_provider.dart';

/// Campana de alertas con badge de pendientes, para los headers de Home.
/// Navega al Centro de Alertas (push, con botón atrás).
class AlertasBell extends ConsumerWidget {
  const AlertasBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(alertasProvider).valueOrNull?.where((a) => !a.resuelta).length ?? 0;

    return IconButton(
      onPressed: () => context.push('/centro-alertas'),
      tooltip: 'Alertas',
      icon: pendientes > 0
          ? Badge(
              label: Text('$pendientes'),
              child: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
            )
          : Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
