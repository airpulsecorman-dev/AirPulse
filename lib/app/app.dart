import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/audio_provider.dart';
import '../presentation/providers/library_provider.dart';
import '../presentation/providers/server_provider.dart';
import '../presentation/pages/library_page.dart';
import '../presentation/pages/player_page.dart';
import '../presentation/pages/server_page.dart';
import '../services/audio_service.dart';
import '../services/library_service.dart';
import '../services/local_server_service.dart';
import '../services/qr_service.dart';

class AirPulseApp extends StatelessWidget {
  const AirPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AudioProvider(AudioService()),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(LibraryService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ServerProvider(LocalServerService(), QRService()),
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
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (_) => const LibraryPage(),
          '/player': (_) => const PlayerPage(),
          '/server': (_) => const ServerPage(),
        },
      ),
    );
  }
}
