import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Catálogo de ejemplos de notificaciones (pantalla de muestra).
const List<Map<String, String>> catalogoNotificaciones = [
  {'icon': '💧', 'title': 'Agua baja', 'body': 'Agrega 2 litros hoy para mantener tus plantas saludables.'},
  {'icon': '🌡️', 'title': 'Temperatura alta', 'body': 'Tu huerta está muy caliente, muévela a la sombra.'},
  {'icon': '✂️', 'title': 'Cosecha lista', 'body': '¡Tu albahaca está lista para cosechar!'},
  {'icon': '⚗️', 'title': 'pH fuera de rango', 'body': 'El pH bajó — tus plantas pueden sufrir.'},
  {'icon': '🌱', 'title': 'Cambio de agua', 'body': 'Han pasado 2 semanas — cambia el agua del reservorio.'},
  {'icon': '✅', 'title': 'Todo bien', 'body': 'Todo bien con tu huerta — ¡que tengas buen día!'},
  {'icon': '🔌', 'title': 'Conexión perdida', 'body': 'Tu huerta perdió conexión hace 2 horas.'},
  {'icon': '🎉', 'title': 'Primera cosecha', 'body': '¡Primera cosecha! Llevas 30 días cultivando.'},
];

final notificationServiceProvider = Provider<NotificationService>((ref) => LocalNotificationService());

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showLocalNotification({required String title, required String body, String? canal});
}

/// Notificaciones locales reales del sistema (Android/iOS).
/// En web o si la plataforma no soporta, queda como no-op seguro.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'hidrosmart_alertas';
  static const _channelName = 'Alertas de la huerta';

  @override
  Future<void> initialize() async {
    if (kIsWeb) return; // web no soporta notificaciones locales nativas
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

      // Canal de Android
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId, _channelName,
        description: 'Avisos de pH, agua, temperatura y cosecha',
        importance: Importance.high,
      ));
      _ready = true;
    } catch (e) {
      _ready = false;
      debugPrint('Notificaciones no disponibles: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb || !_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final a = await android?.requestNotificationsPermission() ?? true;
      final i = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
      return a || i;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showLocalNotification({required String title, required String body, String? canal}) async {
    if (kIsWeb || !_ready) {
      debugPrint('🔔 $title — $body');
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: 'Avisos de pH, agua, temperatura y cosecha',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000;
    await _plugin.show(id, title, body, details);
  }
}
