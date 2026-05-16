/// 🎨 AirPulse Artwork Cache Manager
///
/// Sistema empresarial de caché para artwork de canciones con:
/// - LRU eviction
/// - Memory pooling
/// - Preloading inteligente
/// - Placeholder optimization
///
/// @author AirPulse Performance Team
/// @enterprise
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:airpulse/core/utils/Colors.dart';
import 'package:flutter/widgets.dart';
import 'cache_manager.dart';

/// Manager especializado para cache de artwork
class ArtworkCacheManager {
  static final ArtworkCacheManager _instance = ArtworkCacheManager._internal();
  factory ArtworkCacheManager() => _instance;
  ArtworkCacheManager._internal();

  // Cache de imágenes decodificadas (memoria)
  late final CacheManager<String, ImageProvider> _imageCache;

  // Cache de bytes raw (menor consumo)
  late final CacheManager<String, Uint8List> _bytesCache;

  // Placeholders precargados
  final Map<String, Widget> _placeholders = {};

  /// Inicializa los caches
  void initialize({
    int maxImageCache = 100, // 100 imágenes en memoria
    int maxBytesCache = 500, // 500 artwork como bytes
  }) {
    _imageCache = CacheManager(
      maxSize: maxImageCache,
      ttl: const Duration(minutes: 30),
    );

    _bytesCache = CacheManager(
      maxSize: maxBytesCache,
      ttl: const Duration(hours: 2),
    );
  }

  /// Obtiene artwork desde cache o carga
  ImageProvider? getArtwork(String songId) {
    return _imageCache.get(songId);
  }

  /// Precarga artwork en cache
  Future<void> preloadArtwork(String songId, String? artworkPath) async {
    if (artworkPath == null) return;

    // Verificar si ya está en cache
    if (_imageCache.containsKey(songId)) return;

    try {
      final file = File(artworkPath);
      if (!await file.exists()) return;

      // Leer bytes
      final bytes = await file.readAsBytes();
      _bytesCache.put(songId, bytes);

      // Decodificar y cachear imagen
      final provider = MemoryImage(bytes);
      _imageCache.put(songId, provider);
    } catch (_) {
      // Ignorar errores de carga
    }
  }

  /// Precarga múltiples artworks (batch)
  Future<void> preloadBatch(
    List<String> songIds,
    List<String?> artworkPaths,
  ) async {
    assert(
      songIds.length == artworkPaths.length,
      'Lists must have same length',
    );

    final futures = <Future<void>>[];
    for (int i = 0; i < songIds.length && i < 20; i++) {
      futures.add(preloadArtwork(songIds[i], artworkPaths[i]));
    }

    await Future.wait(futures);
  }

  /// Cachea artwork desde bytes
  void putArtworkBytes(String songId, Uint8List bytes) {
    _bytesCache.put(songId, bytes);
    _imageCache.put(songId, MemoryImage(bytes));
  }

  /// Cachea artwork desde ImageProvider
  void putArtwork(String songId, ImageProvider provider) {
    _imageCache.put(songId, provider);
  }

  /// Obtiene placeholder optimizado
  Widget getPlaceholder(Color color, IconData icon) {
    final key = '${color.value}_${icon.hashCode}';

    return _placeholders.putIfAbsent(
      key,
      () => Container(
        color: color,
        child: Icon(icon, color: AppColors.textSecondary),
      ),
    );
  }

  /// Limpia cache de artwork
  void clear() {
    _imageCache.clear();
    _bytesCache.clear();
  }

  /// Métricas de cache
  CacheMetrics get imageMetrics => _imageCache.metrics;
  CacheMetrics get bytesMetrics => _bytesCache.metrics;

  /// Estado del cache
  String get status {
    return '''
ArtworkCacheManager Status:
- Image Cache: ${_imageCache.length}/${_imageCache.maxSize} (${(_imageCache.hitRate * 100).toStringAsFixed(1)}% hit rate)
- Bytes Cache: ${_bytesCache.length}/${_bytesCache.maxSize} (${(_bytesCache.hitRate * 100).toStringAsFixed(1)}% hit rate)
- Placeholders: ${_placeholders.length}
''';
  }
}
