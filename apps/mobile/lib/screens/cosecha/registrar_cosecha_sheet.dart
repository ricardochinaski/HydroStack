import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cosecha.dart';
import '../../models/planta.dart';
import '../../data/plantas_data.dart';
import '../../providers/huerta_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import 'historial_screen.dart' show cosechasProvider;

/// Abre el formulario para registrar una cosecha manualmente.
Future<void> mostrarRegistrarCosecha(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RegistrarCosechaSheet(),
  );
}

class _RegistrarCosechaSheet extends ConsumerStatefulWidget {
  const _RegistrarCosechaSheet();

  @override
  ConsumerState<_RegistrarCosechaSheet> createState() => _RegistrarCosechaSheetState();
}

class _RegistrarCosechaSheetState extends ConsumerState<_RegistrarCosechaSheet> {
  final _gramosController = TextEditingController();
  final _notaController = TextEditingController();
  String? _plantaId;
  bool _guardando = false;

  @override
  void dispose() {
    _gramosController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prioriza las plantas instaladas en la torre; si no hay, todo el catálogo.
    final huerta = ref.watch(huertaProvider).valueOrNull;
    final instaladas = (huerta?.plantas ?? [])
        .where((p) => p.activa)
        .map((p) => PlantasData.getById(p.plantaId))
        .whereType<Planta>()
        .toList();
    final opciones = instaladas.isNotEmpty ? instaladas : PlantasData.plantas;
    _plantaId ??= opciones.first.id;

    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.content_cut_rounded, color: AppColors.profundo, size: 22),
                  const SizedBox(width: 10),
                  Text('Registrar cosecha', style: TextStyle(
                    fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface,
                  )),
                ],
              ),
              const SizedBox(height: 18),

              Text('PLANTA', style: TextStyle(
                fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: opciones.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = opciones[i];
                    final activa = p.id == _plantaId;
                    return ChoiceChip(
                      label: Text('${p.emoji} ${p.name}'),
                      selected: activa,
                      onSelected: (_) => setState(() => _plantaId = p.id),
                      selectedColor: AppColors.profundo.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontFamily: 'Inter', fontSize: 13,
                        fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                        color: activa ? AppColors.profundo : theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text('CANTIDAD (GRAMOS)', style: TextStyle(
                fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _gramosController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ej: 120',
                  suffixText: 'g',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              Text('NOTA (OPCIONAL)', style: TextStyle(
                fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _notaController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Hojas grandes y aromáticas…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_guardando ? 'Guardando…' : 'Guardar cosecha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.profundo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final gramos = double.tryParse(_gramosController.text.trim().replaceAll(',', '.'));
    if (gramos == null || gramos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida en gramos')),
      );
      return;
    }
    final planta = PlantasData.getById(_plantaId!);
    if (planta == null) return;

    setState(() => _guardando = true);
    final nota = _notaController.text.trim();
    await ref.read(firestoreServiceProvider).registrarCosecha(RegistroCosecha(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      plantaId: planta.id,
      plantaNombre: planta.name,
      emoji: planta.emoji,
      gramos: gramos,
      fecha: DateTime.now(),
      nota: nota.isEmpty ? null : nota,
    ));
    // Refresca el historial.
    ref.invalidate(cosechasProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${planta.emoji} Cosecha de ${planta.name} registrada: ${gramos.toStringAsFixed(0)} g'),
          backgroundColor: AppColors.profundo,
        ),
      );
    }
  }
}
