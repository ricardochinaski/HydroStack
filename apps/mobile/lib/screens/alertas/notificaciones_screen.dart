import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../widgets/notif_mock.dart';
import '../../utils/icon_assets.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = catalogoNotificaciones;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Notificaciones Push')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Catálogo de notificaciones que recibirás',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          SizedBox(height: 16),
          ...notifs.map((n) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: NotifMock(
              icon: iconFromEmoji(n['icon']!),
              title: n['title']!,
              body: n['body']!,
              time: 'EJEMPLO',
            ),
          )),
        ],
      ),
    );
  }
}
