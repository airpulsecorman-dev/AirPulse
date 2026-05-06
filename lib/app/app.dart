import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../presentation/providers/audio_provider.dart';
import '../presentation/providers/library_provider.dart';
import '../presentation/providers/server_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/favorites_provider.dart';
import '../presentation/pages/library_page.dart';
import '../presentation/pages/player_page.dart';
import '../presentation/pages/server_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/register_page.dart';
import '../presentation/pages/favorites_page.dart';
import '../presentation/pages/profile_page.dart';
import '../presentation/pages/edit_profile_page.dart';
import '../presentation/pages/change_password_page.dart';
import '../services/audio_service.dart';
import '../services/library_service.dart';
import '../services/local_server_service.dart';
import '../services/qr_service.dart';
import '../core/di/service_locator.dart';
import '../data/repositories/firebase_auth_repository_impl.dart';
import '../data/repositories/favorites_repository_impl.dart';

class AirPulseApp extends StatelessWidget {
  const AirPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(FirebaseAuthRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(FavoritesRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(sl<AudioService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(sl<LibraryService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ServerProvider(sl<LocalServerService>(), sl<QRService>()),
        ),
      ],
      child: MaterialApp(
        title: 'AirPulse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark,
        home: const _AuthGate(),
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(builder: (_) => const LibraryPage());
          }
          return null;
        },
        routes: {
          '/player': (_) => const PlayerPage(),
          '/server': (_) => const ServerPage(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/favorites': (_) => const FavoritesPage(),
          '/profile': (_) => const ProfilePage(),
          '/edit-profile': (_) => const EditProfilePage(),
          '/change-password': (_) => const ChangePasswordPage(),
        },
      ),
    );
  }
}

/// Decide si ir a Login o a la app según el estado de autenticación.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    // En web siempre mostrar LoginPage (que contiene el panel de conexión con móvil).
    // Las APIs de audio/biblioteca local no están disponibles en web.
    if (kIsWeb) return const LoginPage();

    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          backgroundColor: Color(0xFF0D1B2A),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D8B)),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginPage();
      case AuthStatus.authenticated:
        return const LibraryPage();
    }
  }
}
