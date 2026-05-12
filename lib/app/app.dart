import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
import '../presentation/pages/settings_page.dart';
import '../presentation/pages/nearby_share_page.dart';
import '../services/audio_service.dart';
import '../services/library_service.dart';
import '../services/local_server_service.dart';
import '../services/qr_service.dart';
import '../services/qr_session_service.dart';
import '../core/di/service_locator.dart';
import '../presentation/providers/settings_provider.dart';
import '../data/repositories/firebase_auth_repository_impl.dart';
import '../data/repositories/favorites_repository_impl.dart';

class AirPulseApp extends StatefulWidget {
  const AirPulseApp({super.key});

  @override
  State<AirPulseApp> createState() => _AirPulseAppState();
}

class _AirPulseAppState extends State<AirPulseApp> {
  final _settings = SettingsProvider();
  late final AuthProvider _authProvider;
  late final FavoritesProvider _favoritesProvider;

  @override
  void initState() {
    super.initState();
    _settings.load();
    _favoritesProvider = FavoritesProvider(FavoritesRepositoryImpl());
    _authProvider = AuthProvider(FirebaseAuthRepositoryImpl());
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final userId = _authProvider.currentUser?.id;
    if (_authProvider.status == AuthStatus.authenticated && userId != null) {
      _favoritesProvider.loadFavorites(userId);
    } else if (_authProvider.status == AuthStatus.unauthenticated) {
      _favoritesProvider.clear();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: _settings),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(
          value: _favoritesProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(sl<AudioService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(sl<LibraryService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ServerProvider(
            sl<LocalServerService>(),
            sl<AudioService>(),
            sl<QRService>(),
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
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
          themeMode: settings.themeMode,
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
            '/settings': (_) => const SettingsPage(),
            '/nearby-share': (_) => const NearbySharePage(),
          },
        ),
      ),
    );
  }
}

/// Decide si ir a Login o a la app según el estado de autenticación.
/// En web/desktop, escucha comandos de desconexión remota via RTDB.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _qrService = QrSessionService();
  StreamSubscription<bool>? _disconnectSub;
  String? _watchedSessionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final sessionId = auth.qrSessionId;

    // Solo escuchar en plataformas web/desktop y cuando hay un sessionId de QR
    if ((kIsWeb || _isDesktop()) &&
        sessionId != null &&
        sessionId != _watchedSessionId) {
      _disconnectSub?.cancel();
      _watchedSessionId = sessionId;
      _disconnectSub = _qrService.watchDisconnectCommand(sessionId).listen((
        shouldDisconnect,
      ) async {
        if (!shouldDisconnect || !mounted) return;
        // Limpiar el nodo antes de hacer logout
        await _qrService.clearDisconnectCommand(sessionId);
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu sesión fue revocada desde el dispositivo móvil.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    } else if (sessionId == null && _watchedSessionId != null) {
      _disconnectSub?.cancel();
      _disconnectSub = null;
      _watchedSessionId = null;
    }
  }

  @override
  void dispose() {
    _disconnectSub?.cancel();
    super.dispose();
  }

  bool _isDesktop() {
    const platform = bool.fromEnvironment('dart.library.html');
    if (platform) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticated) {
      return const LibraryPage();
    }

    if (auth.status == AuthStatus.unknown) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4D8B)),
        ),
      );
    }

    return const LoginPage();
  }
}
