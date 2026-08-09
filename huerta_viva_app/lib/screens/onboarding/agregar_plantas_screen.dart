import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/plantas_data.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/icon_assets.dart';

class AgregarPlantasScreen extends ConsumerStatefulWidget {
  const AgregarPlantasScreen({super.key});

  @override
  ConsumerState<AgregarPlantasScreen> createState() => _AgregarPlantasScreenState();
}

class _AgregarPlantasScreenState extends ConsumerState<AgregarPlantasScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Qué plantas tienes?', style: TextStyle(
                    fontFamily: 'Montserrat', fontSize: 26, fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.4,
                  )),
                  SizedBox(height: 6),
                  Text('Elige el tamaño de tu torre y las plantas que tienes.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 16),
                  _TorreSelector(),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: PlantasData.plantas.length,
                itemBuilder: (_, i) {
                  final p = PlantasData.plantas[i];
                  final selected = _selected.contains(p.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(p.id);
                        } else {
                          _selected.add(p.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? AppColors.profundo : Theme.of(context).dividerColor,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: selected ? 0.08 : 0.03),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              plantaIcon(p.id, size: 32),
                              SizedBox(height: 6),
                              Text(p.name, style: TextStyle(
                                fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                                color: selected ? AppColors.profundo : Theme.of(context).colorScheme.onSurface,
                              )),
                              Text(p.harvestDays, style: TextStyle(
                                fontFamily: 'JetBrains Mono', fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                            ],
                          ),
                          if (selected)
                            Positioned(
                              top: 0, right: 0,
                              child: Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.profundo,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selected.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: Text('Agregar ${_selected.length} plantas'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selector del tamaño de la torre: Mini (12) o Normal (24).
class _TorreSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacity = ref.watch(settingsProvider).towerCapacity;
    final notifier = ref.read(settingsProvider.notifier);

    return Row(
      children: [
        _TorreOption(
          label: 'Torre Mini',
          unidades: 12,
          active: capacity == 12,
          onTap: () => notifier.setTowerCapacity(12),
        ),
        const SizedBox(width: 12),
        _TorreOption(
          label: 'Torre Normal',
          unidades: 24,
          active: capacity == 24,
          onTap: () => notifier.setTowerCapacity(24),
        ),
      ],
    );
  }
}

class _TorreOption extends StatelessWidget {
  final String label;
  final int unidades;
  final bool active;
  final VoidCallback onTap;

  const _TorreOption({required this.label, required this.unidades, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.profundo : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.profundoBg : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? AppColors.profundo : Theme.of(context).dividerColor, width: active ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(Icons.view_column_rounded, size: 22, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              Text('$unidades unidades', style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
