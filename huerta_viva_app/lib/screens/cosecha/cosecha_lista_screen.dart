import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/plantas_data.dart';
import '../../models/huerta.dart';
import '../../models/planta.dart';
import '../../providers/huerta_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'registrar_cosecha_sheet.dart';

/// Pantalla Cosecha: muestra el estado real de cada planta instalada en la
/// torre (días de cultivo vs. días a cosecha) y permite registrar cosechas.
class CosechaListaScreen extends ConsumerStatefulWidget {
  const CosechaListaScreen({super.key});

  @override
  ConsumerState<CosechaListaScreen> createState() => _CosechaListaScreenState();
}

class _CosechaListaScreenState extends ConsumerState<CosechaListaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Carga la huerta si aún no está en memoria.
      if (ref.read(huertaProvider).valueOrNull == null) {
        ref.read(huertaProvider.notifier).loadHuerta();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final huertaAsync = ref.watch(huertaProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Cosecha')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarRegistrarCosecha(context),
        backgroundColor: AppColors.profundo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.content_cut_rounded),
        label: const Text('Registrar'),
      ),
      body: huertaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (huerta) {
          final instaladas = (huerta?.plantas ?? []).where((p) => p.activa).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              if (instaladas.isEmpty)
                _emptyState(context)
              else ...[
                Text('MIS PLANTAS', style: AppTypography.techLabel.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                ...instaladas.map((pi) => _plantaCard(context, pi)),
              ],
              const SizedBox(height: 20),
              Text('RECURSOS', style: AppTypography.techLabel.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              _linkCard(context, Icons.menu_book_rounded, 'Guía de cosecha', 'Cómo y cuándo cortar cada planta', '/guia-cosecha'),
              _linkCard(context, Icons.history_rounded, 'Historial de cosechas', 'Registro y totales acumulados', '/historial'),
              _linkCard(context, Icons.eco_rounded, 'Guía de cultivo de la torre', 'Riego, calendario y distribución', '/guia-cultivo'),
            ],
          );
        },
      ),
    );
  }

  // ── Tarjeta de planta con progreso hacia la cosecha ─────────────
  Widget _plantaCard(BuildContext context, PlantaInstalada pi) {
    final theme = Theme.of(context);
    final planta = PlantasData.getById(pi.plantaId);
    if (planta == null) return const SizedBox.shrink();

    final dias = DateTime.now().difference(pi.fechaPlantacion).inDays;
    final objetivo = _diasCosecha(planta);
    final progreso = objetivo > 0 ? (dias / objetivo).clamp(0.0, 1.0) : 0.0;
    final lista = objetivo > 0 && dias >= objetivo;
    final color = lista ? AppColors.profundo : AppColors.circuit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(planta.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planta.name, style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface,
                    )),
                    Text('Nivel ${pi.nivel} · día $dias de ~$objetivo', style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lista ? 'LISTA' : 'CRECIENDO',
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (!lista && objetivo > 0) ...[
            const SizedBox(height: 6),
            Text('Faltan ~${objetivo - dias} días', style: TextStyle(
              fontFamily: 'Inter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant,
            )),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.grass_rounded, size: 48, color: AppColors.gris),
          const SizedBox(height: 12),
          Text('Aún no tienes plantas en la torre', style: TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface,
          )),
          const SizedBox(height: 6),
          Text('Agrega plantas para seguir su progreso hasta la cosecha.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/agregar-plantas'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar plantas'),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context, IconData icon, String title, String subtitle, String route) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.profundo),
        title: Text(title, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        onTap: () => context.push(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Extrae el primer número de "25-30 días" → 25.
  int _diasCosecha(Planta p) {
    final m = RegExp(r'\d+').firstMatch(p.harvestDays);
    return m != null ? int.parse(m.group(0)!) : 0;
  }
}
