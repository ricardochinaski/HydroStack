import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/alertas_bell.dart';

class HomeTranquilo extends StatelessWidget {
  const HomeTranquilo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.circuitBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync_rounded, size: 14, color: AppColors.circuit),
                        const SizedBox(width: 6),
                        Text('BASIC', style: AppTypography.techLabel.copyWith(color: AppColors.circuit)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const AlertasBell(),
                ],
              ),
              const SizedBox(height: 24),
              // Hero: estado de la bomba circuladora
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.profundoBg, AppColors.circuitBg],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.circuit.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(child: Icon(Icons.sync_rounded, size: 38, color: AppColors.circuit)),
                    ),
                    const SizedBox(height: 18),
                    Text('Tu huerta está activa', style: TextStyle(
                      fontFamily: 'Montserrat', fontSize: 23, fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface, height: 1.1,
                    )),
                    const SizedBox(height: 6),
                    Text('La bomba circula el agua en ciclos automáticos.', style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Información importante', style: TextStyle(
                fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface,
              )),
              const SizedBox(height: 12),
              _infoCard(context, Icons.content_cut_rounded, AppColors.profundo,
                'Próxima cosecha', 'Albahaca lista en ~8 días.'),
              const SizedBox(height: 10),
              _infoCard(context, Icons.water_drop_outlined, AppColors.circuit,
                'Cambio de agua', 'Renueva la solución cada 7–14 días. Mide pH/EC si tienes tiras.'),
              const SizedBox(height: 10),
              _infoCard(context, Icons.wb_sunny_outlined, AppColors.warning,
                'Luz', 'Hojas y hierbas: 12–16 h de luz al día para crecer sanas.'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/guia-cultivo'),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Ver guía de cultivo'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/plantas'),
                  icon: const Icon(Icons.eco),
                  label: const Text('Mis plantas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, Color color, String titulo, String detalle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(detalle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
