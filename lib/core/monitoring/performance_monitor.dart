/// 📊 AirPulse Performance Monitor
///
/// Sistema de monitoreo de rendimiento en tiempo real.
///
/// Monitorea:
/// - FPS (Frames per second)
/// - Frame build time
/// - Memory usage
/// - Cache hit rates
/// - Isolates efficiency
///
/// @author AirPulse Performance Team
/// @enterprise
/// @production
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import '../managers/artwork_cache_manager.dart';
import '../services/isolates_manager.dart';

/// Monitor de rendimiento
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Métricas
  final List<Duration> _frameTimes = [];
  DateTime? _lastFrameTime;
  Timer? _metricsTimer;

  bool _isMonitoring = false;
  final _metricsController = StreamController<PerformanceMetrics>.broadcast();

  /// Stream de métricas
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  /// Inicia monitoreo
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameTimes.clear();

    // Frame callback para medir FPS
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // Timer para reportar métricas cada segundo
    _metricsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _reportMetrics(),
    );

    debugPrint('[PerformanceMonitor] 🚀 Monitoreo iniciado');
  }

  /// Detiene monitoreo
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _metricsTimer?.cancel();
    _metricsTimer = null;

    debugPrint('[PerformanceMonitor] ⏹️ Monitoreo detenido');
  }

  void _onFrame(Duration timestamp) {
    if (!_isMonitoring) return;

    if (_lastFrameTime != null) {
      final frameDuration = DateTime.now().difference(_lastFrameTime!);
      _frameTimes.add(frameDuration);

      // Mantener solo últimos 60 frames
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
    }

    _lastFrameTime = DateTime.now();
  }

  void _reportMetrics() {
    if (!_isMonitoring) return;

    final fps = _calculateFPS();
    final avgFrameTime = _calculateAvgFrameTime();
    final jankCount = _countJankFrames();

    final metrics = PerformanceMetrics(
      fps: fps,
      avgFrameTime: avgFrameTime,
      jankCount: jankCount,
      artworkCacheMetrics: ArtworkCacheManager().imageMetrics,
      metadataCacheStats: null, // Async, no bloquear
      isolatesMetrics: IsolatesManager().metrics,
      timestamp: DateTime.now(),
    );

    _metricsController.add(metrics);

    // Log en debug mode
    if (kDebugMode) {
      debugPrint('''
[PerformanceMonitor] 📊
- FPS: ${fps.toStringAsFixed(1)}
- Avg Frame Time: ${avgFrameTime.inMilliseconds}ms
- Jank Frames: $jankCount
- Artwork Cache: ${ArtworkCacheManager().imageMetrics}
''');
    }
  }

  double _calculateFPS() {
    if (_frameTimes.isEmpty) return 0.0;

    final totalTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );

    final avgTime = totalTime.inMicroseconds / _frameTimes.length;
    return 1000000.0 / avgTime; // Convert to FPS
  }

  Duration _calculateAvgFrameTime() {
    if (_frameTimes.isEmpty) return Duration.zero;

    final totalTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (sum, time) => sum + time,
    );

    return Duration(
      microseconds: totalTime.inMicroseconds ~/ _frameTimes.length,
    );
  }

  int _countJankFrames() {
    // Frame jank: > 16.67ms (60 FPS)
    const jankThreshold = Duration(milliseconds: 17);
    return _frameTimes.where((t) => t > jankThreshold).length;
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}

/// Métricas de rendimiento
class PerformanceMetrics {
  final double fps;
  final Duration avgFrameTime;
  final int jankCount;
  final dynamic artworkCacheMetrics;
  final dynamic metadataCacheStats;
  final dynamic isolatesMetrics;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.fps,
    required this.avgFrameTime,
    required this.jankCount,
    this.artworkCacheMetrics,
    this.metadataCacheStats,
    this.isolatesMetrics,
    required this.timestamp,
  });

  bool get hasJank => jankCount > 5;
  bool get isSmooth => fps >= 55.0 && jankCount <= 2;

  String get performanceLevel {
    if (fps >= 58) return '🟢 Excelente';
    if (fps >= 45) return '🟡 Bueno';
    if (fps >= 30) return '🟠 Regular';
    return '🔴 Malo';
  }

  @override
  String toString() =>
      '''
PerformanceMetrics(
  fps: ${fps.toStringAsFixed(1)},
  avgFrameTime: ${avgFrameTime.inMilliseconds}ms,
  jankFrames: $jankCount,
  level: $performanceLevel
)''';
}

/// Widget overlay para mostrar métricas en debug
class PerformanceOverlay extends StatefulWidget {
  final Widget child;

  const PerformanceOverlay({super.key, required this.child});

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final _monitor = PerformanceMonitor();
  PerformanceMetrics? _currentMetrics;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _monitor.startMonitoring();
      _monitor.metricsStream.listen((metrics) {
        if (mounted) {
          setState(() => _currentMetrics = metrics);
        }
      });
    }
  }

  @override
  void dispose() {
    _monitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || _currentMetrics == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 40,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentMetrics!.fps.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: _getFPSColor(_currentMetrics!.fps),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentMetrics!.jankCount > 0)
                  Text(
                    '⚠️ ${_currentMetrics!.jankCount} jank',
                    style: const TextStyle(color: Colors.orange, fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }
}
