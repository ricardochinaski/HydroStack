import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/plantas_provider.dart';
import '../../widgets/planta_tile.dart';
import '../../theme/colors.dart';

class PlantasListScreen extends ConsumerWidget {
  const PlantasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantasAsync = ref.watch(filteredPlantasProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mis Plantas'),
        actions: [
          IconButton(
            tooltip: 'Guía de cultivo',
            icon: Icon(Icons.menu_book_rounded),
            onPressed: () => context.push('/guia-cultivo'),
          ),
          IconButton(
            tooltip: 'Diagnóstico IA',
            icon: Icon(Icons.center_focus_strong_outlined),
            onPressed: () => context.push('/diagnostico-ia'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(context, 'Todas', 'todas', filter, ref),
                  _filterChip(context, '🥬 Hojas', 'hoja', filter, ref),
                  _filterChip(context, '🌿 Hierbas', 'hierba', filter, ref),
                  _filterChip(context, '🍓 Frutos', 'fruto', filter, ref),
                  _filterChip(context, '⭐ Fáciles', 'facil', filter, ref),
                ],
              ),
            ),
          ),
          Expanded(
            child: plantasAsync.isEmpty
                ? Center(child: Text('No se encontraron plantas', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemCount: plantasAsync.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: PlantaTile(
                        planta: plantasAsync[i],
                        onTap: () => context.push('/plantas/${plantasAsync[i].id}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String value, String current, WidgetRef ref) {
    final active = current == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => ref.read(filterProvider.notifier).state = value,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.profundo : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.profundo : Theme.of(context).dividerColor),
          ),
          child: Text(label, style: TextStyle(
            fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          )),
        ),
      ),
    );
  }
}
