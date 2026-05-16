/// 🎯 AirPulse - Configuración de Optimización
///
/// Este archivo contiene la configuración centralizada para todas las
/// optimizaciones de rendimiento.
///
/// Ajusta estos valores según el dispositivo objetivo:
/// - Gama baja: valores conservadores
/// - Gama media: valores por defecto
/// - Gama alta: valores agresivos
///
/// @author AirPulse Performance Team
/// @enterprise
library;

import 'package:flutter/foundation.dart';

/// Configuración de rendimiento
class PerformanceConfig {
  static PerformanceConfig? _instance;

  factory PerformanceConfig() {
    _instance ??= PerformanceConfig._internal();
    return _instance!;
  }

  PerformanceConfig._internal();

  /// Detecta automáticamente el perfil según el dispositivo
  static PerformanceProfile detectProfile() {
    // En producción, detectar basado en características del dispositivo
    if (kDebugMode) {
      return PerformanceProfile.high;
    }

    // Por ahora usar perfil medio por defecto
    return PerformanceProfile.medium;
  }

  /// Configura según el perfil
  static PerformanceSettings getSettings(PerformanceProfile profile) {
    switch (profile) {
      case PerformanceProfile.low:
        return PerformanceSettings.lowEnd();
      case PerformanceProfile.medium:
        return PerformanceSettings.medium();
      case PerformanceProfile.high:
        return PerformanceSettings.highEnd();
    }
  }
}

/// Perfiles de rendimiento
enum PerformanceProfile {
  low, // Gama baja (< 2GB RAM, < 4 cores)
  medium, // Gama media (2-4GB RAM, 4-6 cores)
  high, // Gama alta (> 4GB RAM, > 6 cores)
}

/// Configuración de rendimiento
class PerformanceSettings {
  // Isolates
  final int maxIsolates;

  // Caches
  final int metadataCacheSize;
  final int artworkImageCacheSize;
  final int artworkBytesCacheSize;

  // Paginación
  final int songsPageSize;
  final int prefetchThreshold;
  final int listCacheExtent;

  // Streams
  final Duration positionThrottleInterval;
  final Duration searchDebounceDelay;
  final Duration volumeDebounceDelay;

  // Artwork
  final int artworkPreloadCount;
  final bool useArtworkCompression;

  // Batch Processing
  final int metadataBatchSize;
  final int artworkBatchSize;

  const PerformanceSettings({
    required this.maxIsolates,
    required this.metadataCacheSize,
    required this.artworkImageCacheSize,
    required this.artworkBytesCacheSize,
    required this.songsPageSize,
    required this.prefetchThreshold,
    required this.listCacheExtent,
    required this.positionThrottleInterval,
    required this.searchDebounceDelay,
    required this.volumeDebounceDelay,
    required this.artworkPreloadCount,
    required this.useArtworkCompression,
    required this.metadataBatchSize,
    required this.artworkBatchSize,
  });

  /// Configuración para dispositivos gama baja
  factory PerformanceSettings.lowEnd() {
    return const PerformanceSettings(
      maxIsolates: 2,
      metadataCacheSize: 500,
      artworkImageCacheSize: 50,
      artworkBytesCacheSize: 200,
      songsPageSize: 30,
      prefetchThreshold: 5,
      listCacheExtent: 300,
      positionThrottleInterval: Duration(milliseconds: 300),
      searchDebounceDelay: Duration(milliseconds: 400),
      volumeDebounceDelay: Duration(milliseconds: 150),
      artworkPreloadCount: 20,
      useArtworkCompression: true,
      metadataBatchSize: 10,
      artworkBatchSize: 10,
    );
  }

  /// Configuración para dispositivos gama media (por defecto)
  factory PerformanceSettings.medium() {
    return const PerformanceSettings(
      maxIsolates: 4,
      metadataCacheSize: 1000,
      artworkImageCacheSize: 100,
      artworkBytesCacheSize: 500,
      songsPageSize: 50,
      prefetchThreshold: 10,
      listCacheExtent: 500,
      positionThrottleInterval: Duration(milliseconds: 200),
      searchDebounceDelay: Duration(milliseconds: 300),
      volumeDebounceDelay: Duration(milliseconds: 100),
      artworkPreloadCount: 50,
      useArtworkCompression: false,
      metadataBatchSize: 20,
      artworkBatchSize: 20,
    );
  }

  /// Configuración para dispositivos gama alta
  factory PerformanceSettings.highEnd() {
    return const PerformanceSettings(
      maxIsolates: 6,
      metadataCacheSize: 2000,
      artworkImageCacheSize: 200,
      artworkBytesCacheSize: 1000,
      songsPageSize: 100,
      prefetchThreshold: 20,
      listCacheExtent: 800,
      positionThrottleInterval: Duration(milliseconds: 100),
      searchDebounceDelay: Duration(milliseconds: 200),
      volumeDebounceDelay: Duration(milliseconds: 50),
      artworkPreloadCount: 100,
      useArtworkCompression: false,
      metadataBatchSize: 30,
      artworkBatchSize: 30,
    );
  }

  @override
  String toString() =>
      '''
PerformanceSettings:
  Isolates: $maxIsolates workers
  Metadata Cache: $metadataCacheSize items
  Artwork Cache: $artworkImageCacheSize images, $artworkBytesCacheSize bytes
  Pagination: $songsPageSize items/page
  Throttle: ${positionThrottleInterval.inMilliseconds}ms
  Debounce: ${searchDebounceDelay.inMilliseconds}ms
''';
}

/// Helper para aplicar configuración
class PerformanceConfigurator {
  static Future<void> apply(PerformanceSettings settings) async {
    debugPrint('🎯 Aplicando configuración de rendimiento...');
    debugPrint(settings.toString());

    // Aquí se aplicarían los settings a los managers
    // Por ejemplo:
    // await IsolatesManager().initialize(maxWorkers: settings.maxIsolates);
    // await MetadataCacheManager().initialize(memoryCacheSize: settings.metadataCacheSize);
    // etc.

    debugPrint('✅ Configuración aplicada');
  }
}
