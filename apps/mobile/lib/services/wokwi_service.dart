import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

class LecturaSensor {
  final double ph;
  final double ec;
  final double tempAmbiente;   // °C
  final double humedadAmbiente; // %
  final double tempAgua;        // °C
  final double nivelAgua;       // %
  final String mode;
  final List<int> relays;
  final String heartbeat;

  LecturaSensor({
    required this.ph,
    required this.ec,
    this.tempAmbiente = 24.0,
    this.humedadAmbiente = 62.0,
    this.tempAgua = 20.0,
    this.nivelAgua = 80.0,
    required this.mode,
    required this.relays,
    required this.heartbeat,
  });

  factory LecturaSensor.fromJson(Map<String, dynamic> json) {
    return LecturaSensor(
      ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
      ec: (json['ec'] as num?)?.toDouble() ?? 1.5,
      tempAmbiente: (json['temp_amb'] as num?)?.toDouble() ?? (json['tempAmbiente'] as num?)?.toDouble() ?? 24.0,
      humedadAmbiente: (json['hum_amb'] as num?)?.toDouble() ?? (json['humedadAmbiente'] as num?)?.toDouble() ?? 62.0,
      tempAgua: (json['temp_agua'] as num?)?.toDouble() ?? (json['tempAgua'] as num?)?.toDouble() ?? 20.0,
      nivelAgua: (json['nivel'] as num?)?.toDouble() ?? (json['nivelAgua'] as num?)?.toDouble() ?? 80.0,
      mode: json['mode'] as String? ?? 'eco',
      relays: (json['relays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [0, 0, 0],
      heartbeat: json['heartbeat'] as String? ?? '',
    );
  }
}

class WokwiService {
  WebSocketChannel? _channel;
  final StreamController<LecturaSensor> _controller = StreamController<LecturaSensor>.broadcast();
  StreamSubscription? _subscription;
  bool _connected = false;

  // --- Estado del simulador local (emula el firmware ESP32) ---
  Timer? _simTimer;
  final Random _rng = Random();
  double _simPh = 7.4;
  double _simEc = 0.9;
  double _simTempAmb = 24.0;
  double _simHumAmb = 62.0;
  double _simTempAgua = 20.0;
  double _simNivel = 85.0;
  String _simMode = 'pro';
  bool _simNut = false, _simPhPump = false, _simLed = true;
  bool _simBomba = false, _simAux = false;
  int _nutSecondsLeft = 0, _phSecondsLeft = 0, _bombaSecondsLeft = 0;
  int _simHour = 8;

  bool get isConnected => _connected;
  bool get isSimulating => _simTimer != null;
  Stream<LecturaSensor> get stream => _controller.stream;

  /// Inicia una simulación local de telemetría, replicando la lógica del
  /// firmware: deriva de pH/EC, control On/Off con histéresis de las bombas
  /// y ciclo día/noche del LED. No requiere ningún servidor externo.
  void startSimulation() {
    stopSimulation();
    _connected = true;
    _simTimer = Timer.periodic(const Duration(seconds: 1), (_) => _simTick());
    _simTick();
  }

  void _simTick() {
    // Deriva natural + ruido: el pH tiende a subir, la EC se consume.
    _simPh += (_rng.nextDouble() - 0.42) * 0.07;
    _simEc -= 0.01 + _rng.nextDouble() * 0.012;

    // Control de pH (histéresis): si el pH sube de 6.5, dosifica corrector
    // ácido (pH-) durante 3 s, lo que baja el pH.
    if (_phSecondsLeft > 0) {
      _simPh -= 0.18;
      _phSecondsLeft--;
      _simPhPump = _phSecondsLeft > 0;
    } else if (_simPh > 6.5) {
      _simPhPump = true;
      _phSecondsLeft = 3;
    } else {
      _simPhPump = false;
    }

    // Control de EC (histéresis): si la EC baja de 1.65, dosifica nutrientes
    // durante 3 s, lo que sube la concentración.
    if (_nutSecondsLeft > 0) {
      _simEc += 0.13;
      _nutSecondsLeft--;
      _simNut = _nutSecondsLeft > 0;
    } else if (_simEc < 1.65) {
      _simNut = true;
      _nutSecondsLeft = 3;
    } else {
      _simNut = false;
    }

    // Bomba de circulación: pulso momentáneo disparado por comando 'bomba',
    // igual que nutrientes/pH- (no tiene lógica automática propia).
    if (_bombaSecondsLeft > 0) {
      _bombaSecondsLeft--;
      _simBomba = _bombaSecondsLeft > 0;
    }

    _simPh = _simPh.clamp(4.5, 8.5);
    _simEc = _simEc.clamp(0.2, 3.0);

    // Ciclo día/noche acelerado para verlo conmutar en la demo.
    _simHour = (_simHour + 1) % 24;
    _simLed = _simHour >= 6 && _simHour < 20;

    // Temperatura ambiente: oscila según día/noche (más cálido de día).
    final objetivoTempAmb = _simLed ? 26.0 : 21.0;
    _simTempAmb += (objetivoTempAmb - _simTempAmb) * 0.04 + (_rng.nextDouble() - 0.5) * 0.15;

    // Humedad ambiente: inversa a la temperatura, con ruido.
    final objetivoHum = _simLed ? 58.0 : 68.0;
    _simHumAmb += (objetivoHum - _simHumAmb) * 0.04 + (_rng.nextDouble() - 0.5) * 0.4;

    // Temperatura del agua: sigue al ambiente pero amortiguada e inercial.
    _simTempAgua += (_simTempAmb - 2.0 - _simTempAgua) * 0.02 + (_rng.nextDouble() - 0.5) * 0.05;

    // Nivel del agua: baja lentamente (evaporación/consumo); más rápido si la
    // bomba de nutrientes está dosificando.
    _simNivel -= 0.05 + (_simNut ? 0.15 : 0.0) + _rng.nextDouble() * 0.03;

    _simTempAmb = _simTempAmb.clamp(16.0, 32.0);
    _simHumAmb = _simHumAmb.clamp(40.0, 85.0);
    _simTempAgua = _simTempAgua.clamp(14.0, 28.0);
    _simNivel = _simNivel.clamp(0.0, 100.0);

    _controller.add(LecturaSensor(
      ph: _simPh,
      ec: _simEc,
      tempAmbiente: _simTempAmb,
      humedadAmbiente: _simHumAmb,
      tempAgua: _simTempAgua,
      nivelAgua: _simNivel,
      mode: _simMode,
      // [nutrientes, pH-, luz, bomba, auxiliar] — mismo orden que el hardware real.
      relays: [
        _simNut ? 1 : 0,
        _simPhPump ? 1 : 0,
        _simLed ? 1 : 0,
        _simBomba ? 1 : 0,
        _simAux ? 1 : 0,
      ],
      heartbeat: DateTime.now().toIso8601String(),
    ));
  }

  void stopSimulation() {
    _simTimer?.cancel();
    _simTimer = null;
    // Si no hay WebSocket activo, la conexión queda cerrada al parar la
    // simulación (permite rearrancarla después).
    if (_channel == null) _connected = false;
  }

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _connected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          final raw = data is String ? data : utf8.decode(data as List<int>);
          final lines = raw.trim().split('\n');
          for (final line in lines) {
            if (line.startsWith('{')) {
              try {
                final json = jsonDecode(line) as Map<String, dynamic>;
                if (json.containsKey('ph') && json.containsKey('ec')) {
                  _controller.add(LecturaSensor.fromJson(json));
                }
              } catch (_) {}
            }
          }
        },
        onError: (e) {
          _connected = false;
          _controller.addError(e);
        },
        onDone: () {
          _connected = false;
        },
      );
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  Future<void> sendCommand(String cmd, String value) async {
    // En modo simulación local, el comando actúa sobre el estado interno.
    if (isSimulating) {
      switch (cmd) {
        case 'modo':
          _simMode = value;
          break;
        case 'regar': // forzar dosificación de nutrientes
          _simNut = true;
          _nutSecondsLeft = 3;
          break;
        case 'ph': // forzar dosificación de corrector pH-
          _simPhPump = true;
          _phSecondsLeft = 3;
          break;
        case 'luz': // alternar iluminación
          _simLed = !_simLed;
          break;
        case 'rellenar': // reponer el nivel del depósito
          _simNivel = 95.0;
          break;
        case 'bomba': // forzar pulso de circulación/riego
          _simBomba = true;
          _bombaSecondsLeft = 3;
          break;
        case 'auxiliar': // alternar relé de reserva
          _simAux = !_simAux;
          break;
      }
      _simTick();
      return;
    }
    if (_channel == null || !_connected) return;
    final msg = jsonEncode({'cmd': cmd, 'value': value});
    _channel!.sink.add(msg);
  }

  Future<void> sendRaw(String jsonStr) async {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonStr);
  }

  void disconnect() {
    stopSimulation();
    _subscription?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
