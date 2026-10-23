import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../providers/device_provider.dart';
import '../../providers/wokwi_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/wokwi_service.dart';

class SimuladorScreen extends ConsumerStatefulWidget {
  const SimuladorScreen({super.key});

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final _urlController = TextEditingController(text: 'ws://localhost:49152');
  final _deviceController = TextEditingController();
  bool _conectando = false;
  bool _mostrarWs = false;
  bool _deviceInicializado = false;

  @override
  void dispose() {
    _urlController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _guardarIdDesarrollo() async {
    final id = _deviceController.text.trim().toUpperCase();
    if (id.isEmpty) return;
    await ref.read(settingsProvider.notifier).setDevelopmentDeviceId(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$id guardado solo para desarrollo. No otorga ownership.'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _iniciarSimulacion() {
    ref.read(wokwiServiceProvider).startSimulation();
    ref.read(wokwiConnectionProvider.notifier).state = true;
  }

  Future<void> _conectarWs() async {
    setState(() => _conectando = true);
    try {
      await ref.read(wokwiServiceProvider).connect(_urlController.text);
      ref.read(wokwiConnectionProvider.notifier).state = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _conectando = false);
  }

  void _desconectar() {
    ref.read(wokwiServiceProvider).disconnect();
    ref.read(wokwiConnectionProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final conectado = ref.watch(wokwiConnectionProvider);
    final simulando = ref.read(wokwiServiceProvider).isSimulating;
    final lecturasAsync = ref.watch(wokwiLecturaProvider);
    final settings = ref.watch(settingsProvider);
    final usarHardware = settings.usarHardware;
    final authorizedDevice = ref.watch(authorizedDeviceProvider);

    if (!_deviceInicializado) {
      _deviceController.text = settings.developmentDeviceId;
      _deviceInicializado = true;
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        title: const Text('FUENTE DE DATOS', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, letterSpacing: 1)),
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1C17),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: usarHardware ? AppColors.circuit : AppColors.gris.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        usarHardware ? Icons.sensors_rounded : Icons.computer_rounded,
                        size: 18,
                        color: usarHardware ? AppColors.circuit : AppColors.gris,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        usarHardware ? 'HARDWARE / RTDB' : 'SIMULADOR LOCAL',
                        style: AppTypography.techLabelSmall.copyWith(
                          color: usarHardware ? AppColors.circuit : AppColors.gris,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: usarHardware,
                        activeThumbColor: AppColors.circuit,
                        activeTrackColor: AppColors.circuit.withValues(alpha: 0.4),
                        onChanged: (v) => ref.read(settingsProvider.notifier).setUsarHardware(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    usarHardware
                        ? 'Producción usa solo dispositivos cuyo ownership fue validado en Firestore. El ID manual está aislado como modo de desarrollo.'
                        : 'Datos generados por el simulador interno. No se requiere ningún hardware físico.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.gris, height: 1.5),
                  ),
                  if (usarHardware) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'MODO DEV MANUAL',
                            style: AppTypography.techLabelSmall.copyWith(color: AppColors.gris),
                          ),
                        ),
                        Switch(
                          value: settings.useDevelopmentDevice,
                          activeThumbColor: AppColors.warning,
                          onChanged: (v) => ref.read(settingsProvider.notifier).setUseDevelopmentDevice(v),
                        ),
                      ],
                    ),
                    Text(
                      settings.useDevelopmentDevice
                          ? 'ADVERTENCIA: el ID manual es solo laboratorio y no demuestra propiedad del dispositivo.'
                          : 'Modo real: el acceso se resuelve desde devices/{deviceId}.ownerUid.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        color: settings.useDevelopmentDevice ? AppColors.warning : AppColors.gris,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (settings.useDevelopmentDevice) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _deviceController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, color: Colors.white, letterSpacing: 1),
                              decoration: InputDecoration(
                                labelText: 'ID DESARROLLO',
                                hintText: 'HS-001',
                                hintStyle: TextStyle(color: AppColors.gris.withValues(alpha: 0.5)),
                                prefixIcon: Icon(Icons.science_outlined, size: 18, color: AppColors.warning),
                                filled: true,
                                fillColor: const Color(0xFF1A1D1C),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.borde.withValues(alpha: 0.3)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _guardarIdDesarrollo,
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: const Text('GUARDAR', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, letterSpacing: 1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DEV RTDB: dispositivos/${settings.developmentDeviceId}/telemetria',
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.warning),
                      ),
                    ] else ...[
                      authorizedDevice.when(
                        data: (device) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.circuit.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            device == null
                                ? 'SIN DISPOSITIVO REAL AUTORIZADO\nEl claim seguro todavía está pendiente.'
                                : 'AUTORIZADO: ${device.alias} (${device.deviceId})\nRTDB: dispositivos/${device.deviceId}/telemetria',
                            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: device == null ? AppColors.gris : AppColors.circuit, height: 1.5),
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Text(
                          'No se pudo verificar ownership.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!usarHardware) ...[
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: conectado ? AppColors.circuit : AppColors.danger,
                    shape: BoxShape.circle,
                  )),
                  const SizedBox(width: 6),
                  Text(
                    conectado ? (simulando ? 'SIMULANDO (LOCAL)' : 'CONECTADO (WS)') : 'DETENIDO',
                    style: AppTypography.techLabelSmall.copyWith(color: conectado ? AppColors.circuit : AppColors.danger),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: conectado ? _desconectar : _iniciarSimulacion,
                  icon: Icon(conectado ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    conectado ? 'DETENER' : 'INICIAR SIMULACIÓN',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: conectado ? AppColors.danger : AppColors.circuit,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!conectado) ...[
                GestureDetector(
                  onTap: () => setState(() => _mostrarWs = !_mostrarWs),
                  child: Row(
                    children: [
                      Icon(_mostrarWs ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.gris),
                      const SizedBox(width: 4),
                      Text('Avanzado: conectar a Wokwi real (WebSocket)',
                        style: AppTypography.techLabelSmall.copyWith(color: AppColors.gris)),
                    ],
                  ),
                ),
                if (_mostrarWs) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'ws://localhost:49152',
                            hintStyle: TextStyle(color: AppColors.gris.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: const Color(0xFF1A1D1C),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borde.withValues(alpha: 0.3))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _conectando ? null : _conectarWs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        child: _conectando
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('WS', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ],
            ],
            const SizedBox(height: 8),
            Text('TELEMETRÍA EN VIVO', style: AppTypography.techLabel.copyWith(color: AppColors.circuit)),
            const SizedBox(height: 12),
            lecturasAsync.when(
              data: (lectura) => _buildTelemetryCard(lectura),
              loading: () => Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Text(
                  conectado ? 'Esperando telemetría...' : 'Esperando fuente de datos...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', color: AppColors.gris, fontSize: 13),
                ),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Text('Esperando datos...', style: TextStyle(fontFamily: 'Inter', color: AppColors.gris, fontSize: 13)),
              ),
            ),
            if (conectado) ...[
              const SizedBox(height: 20),
              Text('ACTUADORES REALES', style: AppTypography.techLabel.copyWith(color: AppColors.circuit)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _cmdButton('REGAR NUT', 'regar', '1', AppColors.profundo),
                  const SizedBox(width: 8),
                  _cmdButton('LUZ', 'luz', '1', AppColors.warning),
                  const SizedBox(width: 8),
                  _cmdButton('BOMBA', 'bomba', '1', AppColors.circuit),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _cmdButton('AUX', 'auxiliar', '1', AppColors.info),
                  const SizedBox(width: 8),
                  _cmdButton('DOSIF. pH-*', 'ph', '1', AppColors.gris),
                  const SizedBox(width: 8),
                  _cmdButton('RELLENAR*', 'rellenar', '1', AppColors.gris),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('* sin actuador físico en este hardware — solo afecta al simulador',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.gris),
                ),
              ),
              const SizedBox(height: 16),
              Text('MODELO', style: AppTypography.techLabel.copyWith(color: AppColors.circuit)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _cmdButton('BASIC', 'modo', 'basic', AppColors.info),
                  const SizedBox(width: 8),
                  _cmdButton('ECO', 'modo', 'eco', AppColors.eco),
                  const SizedBox(width: 8),
                  _cmdButton('PRO', 'modo', 'pro', AppColors.pro),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _cmdButton(String label, String cmd, String value, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => enviarComando(ref, cmd, value),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9.5, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildTelemetryCard(LecturaSensor lectura) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow('pH', lectura.ph.toStringAsFixed(2), '5.5 - 6.5', AppColors.circuit),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('EC', '${lectura.ec.toStringAsFixed(2)} mS/cm', '1.65 - 1.95', AppColors.profundo),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('T. AIRE', '${lectura.tempAmbiente.toStringAsFixed(1)} °C', '22 - 28', AppColors.warning),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('HUMEDAD', '${lectura.humedadAmbiente.toStringAsFixed(0)} %', '55 - 70', AppColors.info),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('T. AGUA', '${lectura.tempAgua.toStringAsFixed(1)} °C', '18 - 22', AppColors.circuit),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('NIVEL', '${lectura.nivelAgua.toStringAsFixed(0)} %', lectura.nivelAgua < 25 ? 'BAJO' : 'OK',
              lectura.nivelAgua < 25 ? AppColors.danger : AppColors.profundo),
          const Divider(color: AppColors.borde, height: 24),
          _metricRow('MODELO', lectura.mode.toUpperCase(), '', AppColors.info),
          const Divider(color: AppColors.borde, height: 24),
          Text('RELÉS', style: AppTypography.techLabelSmall.copyWith(color: AppColors.gris)),
          const SizedBox(height: 6),
          Row(children: [
            _relayChip('NUTR.', lectura.relays.isNotEmpty ? lectura.relays[0] == 1 : false),
            const SizedBox(width: 6),
            _relayChip('LED', lectura.relays.length > 2 ? lectura.relays[2] == 1 : false),
            const SizedBox(width: 6),
            _relayChip('BOMBA', lectura.relays.length > 3 ? lectura.relays[3] == 1 : false),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _relayChip('AUX', lectura.relays.length > 4 ? lectura.relays[4] == 1 : false),
            const SizedBox(width: 6),
            _relayChip('pH- (sim)', lectura.relays.length > 1 ? lectura.relays[1] == 1 : false),
            const SizedBox(width: 6),
            const Expanded(child: SizedBox.shrink()),
          ]),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, String range, Color accent) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: AppTypography.techLabelSmall.copyWith(color: AppColors.gris))),
        Expanded(
          child: Text(value, style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w800, color: accent,
          )),
        ),
        if (range.isNotEmpty)
          Text(range, style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 8, color: AppColors.gris)),
      ],
    );
  }

  Widget _relayChip(String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.profundo : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppColors.profundo : AppColors.gris.withValues(alpha: 0.3)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          fontFamily: 'JetBrains Mono', fontSize: 8, letterSpacing: 0.5,
          color: active ? Colors.white : AppColors.gris,
        )),
      ),
    );
  }
}
