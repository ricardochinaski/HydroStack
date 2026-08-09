import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'widgets/app_scaffold.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/elegir_modo_screen.dart';
import 'screens/onboarding/conectar_esp32_screen.dart';
import 'screens/onboarding/agregar_plantas_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/plantas/plantas_list_screen.dart';
import 'screens/plantas/planta_detail_screen.dart';
import 'screens/plantas/diagnostico_ia_screen.dart';
import 'screens/control/panel_sensores_screen.dart';
import 'screens/control/riego_manual_screen.dart';
import 'screens/control/programar_riego_screen.dart';
import 'screens/control/nutrientes_screen.dart';
import 'screens/alertas/notificaciones_screen.dart';
import 'screens/alertas/centro_alertas_screen.dart';
import 'screens/cosecha/cosecha_lista_screen.dart';
import 'screens/cosecha/guia_cosecha_screen.dart';
import 'screens/cosecha/guia_cultivo_screen.dart';
import 'screens/cosecha/historial_screen.dart';
import 'screens/ajustes/perfil_screen.dart';
import 'screens/ajustes/notif_prefs_screen.dart';
import 'screens/ajustes/cambiar_modo_screen.dart';
import 'screens/ajustes/mi_huerta_screen.dart';
import 'screens/ajustes/ayuda_screen.dart';
import 'screens/ajustes/privacidad_screen.dart';
import 'screens/ajustes/acerca_screen.dart';
import 'screens/dev/simulador_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;

      final currentPath = state.uri.path;

      if (currentPath == '/splash') return null;

      if (!isLoggedIn && currentPath != '/login') return '/login';

      if (isLoggedIn) {
        if (currentPath == '/login') return '/elegir-modo';
        if (currentPath == '/') return '/home';

        if (user.mode == AppMode.basic && currentPath == '/elegir-modo') return null;
        if (!user.esp32Connected && currentPath == '/conectar-esp32') return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => LoginScreen()),
      GoRoute(path: '/elegir-modo', builder: (_, _) => ElegirModoScreen()),
      GoRoute(path: '/conectar-esp32', builder: (_, _) => ConectarEsp32Screen()),
      GoRoute(path: '/agregar-plantas', builder: (_, _) => AgregarPlantasScreen()),

      ShellRoute(
        builder: (_, _, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => HomeScreen()),
          GoRoute(path: '/plantas', builder: (_, _) => PlantasListScreen()),
          GoRoute(path: '/plantas/:id', builder: (_, state) => PlantaDetailScreen(plantaId: state.pathParameters['id']!)),
          GoRoute(path: '/diagnostico-ia', builder: (_, _) => DiagnosticoIAScreen()),
          GoRoute(path: '/panel-sensores', builder: (_, _) => PanelSensoresScreen()),
          GoRoute(path: '/riego-manual', builder: (_, _) => RiegoManualScreen()),
          GoRoute(path: '/programar-riego', builder: (_, _) => ProgramarRiegoScreen()),
          GoRoute(path: '/nutrientes', builder: (_, _) => NutrientesScreen()),
          GoRoute(path: '/notificaciones', builder: (_, _) => NotificacionesScreen()),
          GoRoute(path: '/centro-alertas', builder: (_, _) => CentroAlertasScreen()),
          GoRoute(path: '/cosecha-lista', builder: (_, _) => CosechaListaScreen()),
          GoRoute(path: '/guia-cosecha', builder: (_, _) => GuiaCosechaScreen()),
          GoRoute(path: '/guia-cultivo', builder: (_, _) => const GuiaCultivoScreen()),
          GoRoute(path: '/historial', builder: (_, _) => HistorialScreen()),
          GoRoute(path: '/perfil', builder: (_, _) => PerfilScreen()),
          GoRoute(path: '/notif-prefs', builder: (_, _) => NotifPrefsScreen()),
          GoRoute(path: '/cambiar-modo', builder: (_, _) => CambiarModoScreen()),
          GoRoute(path: '/mi-huerta', builder: (_, _) => MiHuertaScreen()),
          GoRoute(path: '/ayuda', builder: (_, _) => AyudaScreen()),
          GoRoute(path: '/privacidad', builder: (_, _) => PrivacidadScreen()),
          GoRoute(path: '/acerca', builder: (_, _) => AcercaScreen()),
          GoRoute(path: '/simulador', builder: (_, _) => SimuladorScreen()),
        ],
      ),
    ],
  );
});
