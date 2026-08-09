import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';
import '../../theme/colors.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return MockAIService();
});

class DiagnosticoIAScreen extends ConsumerStatefulWidget {
  const DiagnosticoIAScreen({super.key});

  @override
  ConsumerState<DiagnosticoIAScreen> createState() => _DiagnosticoIAScreenState();
}

class _DiagnosticoIAScreenState extends ConsumerState<DiagnosticoIAScreen> {
  bool _analyzing = false;
  bool _photoTaken = false;
  String? _result;
  final _plantaController = TextEditingController();

  @override
  void dispose() {
    _plantaController.dispose();
    super.dispose();
  }

  void _takePhoto() {
    setState(() {
      _photoTaken = true;
      _result = null;
    });
  }

  void _analyze() {
    final plantName = _plantaController.text.trim();
    if (plantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escribe el nombre de la planta')),
      );
      return;
    }
    setState(() => _analyzing = true);
    ref.read(aiServiceProvider).diagnosticarPlanta('mock.jpg', plantName).then((res) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _result = res;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Diagnóstico IA')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.camera_alt_rounded, size: 56, color: AppColors.profundo)),
            SizedBox(height: 16),
            Center(
              child: Text('Fotografía la hoja o planta que se vea diferente',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt),
                label: Text(_photoTaken ? 'Volver a fotografiar' : 'Abrir cámara'),
              ),
            ),
            if (_photoTaken) ...[
              SizedBox(height: 20),
              TextField(
                controller: _plantaController,
                decoration: InputDecoration(
                  labelText: '¿Qué planta es?',
                  hintText: 'Ej: Lechuga, Albahaca...',
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _analyzing ? null : _analyze,
                  child: _analyzing
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Analizar planta'),
                ),
              ),
            ],
            if (_result != null) ...[
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.profundoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.profundo.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.search_rounded, size: 18, color: AppColors.profundo),
                      SizedBox(width: 8),
                      Text('Resultado',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ]),
                    SizedBox(height: 10),
                    Text(_result!, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurface, height: 1.6)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
