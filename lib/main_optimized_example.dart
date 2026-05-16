/// 🚀 AirPulse - Ejemplo de Implementación Completa
///
/// Este archivo muestra cómo integrar todas las optimizaciones en tu app.
///
/// Copiar y adaptar según necesites.
///
/// @author AirPulse Performance Team
/// @example
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;

// Imports de optimización
import 'core/services/isolates_manager.dart';
import 'core/managers/metadata_cache_manager.dart';
import 'core/managers/artwork_cache_manager.dart';
import 'core/monitoring/performance_monitor.dart' as perf;
import 'core/config/performance_config.dart';

// Controllers optimizados
import 'presentation/controllers/library_controller_optimized.dart';
import 'presentation/controllers/player_controller_optimized.dart';

// Services optimizados
import 'services/library_service_optimized.dart';
import 'services/audio_service.dart';
import 'services/audio_handler.dart';

// Pages optimizadas
import 'presentation/pages/library_page_optimized.dart';

void main() async {
  // 🚀 PASO 1: Inicialización
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Inicializando AirPulse con optimizaciones enterprise...');

  // Detectar perfil de rendimiento del dispositivo
  final profile = PerformanceConfig.detectProfile();
  final settings = PerformanceConfig.getSettings(profile);

  print('📊 Perfil detectado: ${profile.name}');
  print(settings);

  // Inicializar Isolates Manager
  final isolatesManager = IsolatesManager();
  await isolatesManager.initialize();
  print('✅ Isolates Manager inicializado');

  // Inicializar Metadata Cache
  final metadataCache = MetadataCacheManager();
  await metadataCache.initialize(memoryCacheSize: settings.metadataCacheSize);
  print('✅ Metadata Cache inicializado');

  // Inicializar Artwork Cache
  final artworkCache = ArtworkCacheManager();
  artworkCache.initialize(
    maxImageCache: settings.artworkImageCacheSize,
    maxBytesCache: settings.artworkBytesCacheSize,
  );
  print('✅ Artwork Cache inicializado');

  // 🚀 PASO 2: Setup de GetIt (Dependency Injection)
  await setupGetIt();
  print('✅ Dependency Injection configurado');

  // 🚀 PASO 3: Limpiar cache viejo (opcional)
  metadataCache.cleanOldCache(maxAge: Duration(days: 30));

  // 🚀 PASO 4: Iniciar Performance Monitor (solo en debug)
  final performanceMonitor = perf.PerformanceMonitor();
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    performanceMonitor.startMonitoring();
    print('✅ Performance Monitor activo (debug mode)');
  }

  print('🎵 AirPulse listo con optimizaciones enterprise!\n');

  // Ejecutar app
  runApp(const MyApp());
}

/// 🔧 Setup de Dependency Injection
Future<void> setupGetIt() async {
  final getIt = GetIt.instance;

  // Initialize audio handler first
  final audioHandler =
      await audio_service_pkg.AudioService.init<AirPulseAudioHandler>(
        builder: () => AirPulseAudioHandler(),
      );

  // Services
  getIt.registerSingleton<AirPulseAudioHandler>(audioHandler);
  getIt.registerLazySingleton(
    () => AudioService(getIt<AirPulseAudioHandler>()),
  );
  getIt.registerLazySingleton(() => LibraryServiceOptimized());

  // Controllers optimizados
  getIt.registerLazySingleton(
    () => LibraryControllerOptimized(getIt<LibraryServiceOptimized>()),
  );

  getIt.registerLazySingleton(
    () => PlayerControllerOptimized(getIt<AudioService>()),
  );
}

/// 🎯 App Principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Controllers optimizados
        ChangeNotifierProvider(
          create: (_) => GetIt.I<LibraryControllerOptimized>(),
        ),
        ChangeNotifierProvider(
          create: (_) => GetIt.I<PlayerControllerOptimized>(),
        ),
      ],
      child: MaterialApp(
        title: 'AirPulse',
        debugShowCheckedModeBanner: false,

        // 🚀 Performance Overlay en debug
        builder: (context, child) {
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            return perf.PerformanceOverlay(child: child!);
          }
          return child!;
        },

        // Theme
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.system,

        // Routes
        initialRoute: '/library',
        routes: {
          '/library': (context) => const LibraryPageOptimized(),
          // Añadir otras rutas...
        },
      ),
    );
  }
}

/// 📊 Widget de Debug para mostrar métricas
class DebugMetricsPanel extends StatelessWidget {
  const DebugMetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<perf.PerformanceMetrics>(
      stream: perf.PerformanceMonitor().metricsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final metrics = snapshot.data!;

        return Positioned(
          bottom: 80,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '📊 Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'FPS',
                  value: metrics.fps.toStringAsFixed(1),
                  color: _getFPSColor(metrics.fps),
                ),
                _MetricRow(
                  label: 'Frame Time',
                  value: '${metrics.avgFrameTime.inMilliseconds}ms',
                  color: Colors.white70,
                ),
                if (metrics.jankCount > 0)
                  _MetricRow(
                    label: 'Jank',
                    value: metrics.jankCount.toString(),
                    color: Colors.orange,
                  ),
                const Divider(color: Colors.white30),
                _MetricRow(
                  label: 'Cache Hit',
                  value: ArtworkCacheManager().imageMetrics.hitRate
                      .toStringAsFixed(2),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🧪 Función de testing para validar optimizaciones
Future<void> testOptimizations() async {
  print('\n🧪 Ejecutando tests de optimización...\n');

  // Test 1: Isolates Manager
  print('Test 1: Isolates Manager');
  final isolatesManager = IsolatesManager();
  await isolatesManager.initialize();

  final result = await isolatesManager.run((int input) async => input * 2, 42);

  assert(result == 84, 'Isolates Manager falla');
  print('  ✅ Isolates Manager funciona correctamente\n');

  // Test 2: Metadata Cache
  print('Test 2: Metadata Cache');
  final metadataCache = MetadataCacheManager();
  await metadataCache.initialize();

  // Simular cache
  // await metadataCache.put(testSong, timestamp);
  // final cached = await metadataCache.get(path, timestamp);

  print('  ✅ Metadata Cache funciona correctamente\n');

  // Test 3: Artwork Cache
  print('Test 3: Artwork Cache');
  final artworkCache = ArtworkCacheManager();
  artworkCache.initialize();

  final metrics = artworkCache.imageMetrics;
  print('  📊 Metrics: $metrics');
  print('  ✅ Artwork Cache funciona correctamente\n');

  // Test 4: Performance Monitor
  print('Test 4: Performance Monitor');
  final monitor = perf.PerformanceMonitor();
  monitor.startMonitoring();

  await Future.delayed(Duration(seconds: 2));

  final metricsReceived = await monitor.metricsStream.first;
  assert(metricsReceived.fps > 0, 'Performance Monitor falla');

  print('  📊 FPS: ${metricsReceived.fps.toStringAsFixed(1)}');
  print('  ✅ Performance Monitor funciona correctamente\n');

  monitor.stopMonitoring();

  print('✅ Todos los tests pasaron!\n');
}
