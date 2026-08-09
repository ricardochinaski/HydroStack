import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/planta_info_data.dart';
import '../../models/planta_info.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/icon_assets.dart';

class PlantaDetailScreen extends StatelessWidget {
  final String plantaId;

  const PlantaDetailScreen({super.key, required this.plantaId});

  @override
  Widget build(BuildContext context) {
    final info = PlantaInfoData.getById(plantaId);

    if (info == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text('Planta no encontrada')),
        body: Center(child: Text('No se encontró información para esta planta')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(info.nombre, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/plantas'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(info: info),
            SizedBox(height: 20),
            _MetricsRow(info: info),
            SizedBox(height: 20),
            _CaracteristicasCard(info: info),
            SizedBox(height: 20),
            _PropiedadesVitaminasGrid(info: info),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final PlantaInfo info;
  const _HeaderSection({required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
              ),
              child: Center(child: plantaIcon(info.id, size: 48)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.nombre, style: TextStyle(
                    fontFamily: 'Montserrat', fontSize: 26, fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface, height: 1.1,
                  )),
                  SizedBox(height: 6),
                  Text(info.categoria.toUpperCase(), style: AppTypography.techLabel.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final PlantaInfo info;
  const _MetricsRow({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricCard(label: 'PH IDEAL', value: info.phIdeal, accent: AppColors.circuit)),
        SizedBox(width: 10),
        Expanded(child: _MetricCard(label: 'EC IDEAL', value: info.ecIdeal, accent: AppColors.profundo)),
        SizedBox(width: 10),
        Expanded(child: _MetricCard(label: 'COSECHA', value: info.tiempoCosecha, accent: AppColors.info)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricCard({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.techLabelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 8),
          Text(value.split(' ').first, style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w800,
            color: accent, height: 1.1,
          )),
          if (value.contains(' ')) ...[
            SizedBox(height: 2),
            Text(value.substring(value.indexOf(' ') + 1), style: TextStyle(
              fontFamily: 'JetBrains Mono', fontSize: 8, letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ],
        ],
      ),
    );
  }
}

class _CaracteristicasCard extends StatelessWidget {
  final PlantaInfo info;
  const _CaracteristicasCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CARACTERÍSTICAS', style: AppTypography.techLabel.copyWith(color: AppColors.profundo)),
          SizedBox(height: 10),
          Text(info.caracteristicas, style: TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.6,
          )),
        ],
      ),
    );
  }
}

class _PropiedadesVitaminasGrid extends StatelessWidget {
  final PlantaInfo info;
  const _PropiedadesVitaminasGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROPIEDADES', style: AppTypography.techLabel.copyWith(color: AppColors.circuit)),
                SizedBox(height: 10),
                Text(info.propiedades, style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.6,
                )),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VITAMINAS', style: AppTypography.techLabel.copyWith(color: AppColors.profundo)),
                SizedBox(height: 10),
                ...info.vitaminas.map((v) => Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(v, style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
