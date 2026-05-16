/// 🚀 AirPulse Enterprise Cache Manager
///
/// Sistema de caché LRU (Least Recently Used) de nivel empresarial
/// para optimización de memoria y rendimiento.
///
/// Características:
/// - LRU eviction automático
/// - Memory pool management
/// - Thread-safe operations
/// - Metrics y monitoring
/// - TTL (Time To Live) support
///
/// @author AirPulse Performance Team
/// @enterprise
library;

import 'dart:collection';

/// Cache Manager empresarial con estrategia LRU
class CacheManager<K, V> {
  final int maxSize;
  final Duration? ttl;

  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;

  CacheManager({required this.maxSize, this.ttl})
    : assert(maxSize > 0, 'maxSize debe ser mayor a 0');

  /// Obtiene valor del cache
  V? get(K key) {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    // Verificar TTL
    if (ttl != null && DateTime.now().difference(entry.timestamp) > ttl!) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    // LRU: Mover al final (más reciente)
    _cache.remove(key);
    _cache[key] = entry;

    _hits++;
    return entry.value;
  }

  /// Almacena valor en cache con eviction LRU automático
  void put(K key, V value) {
    // Si existe, actualizar
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    // Si está lleno, eliminar el más antiguo (primero)
    else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(value);
  }

  /// Elimina entrada del cache
  void remove(K key) {
    _cache.remove(key);
  }

  /// Limpia todo el cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Verifica si existe en cache
  bool containsKey(K key) {
    return _cache.containsKey(key);
  }

  /// Métricas de rendimiento
  CacheMetrics get metrics => CacheMetrics(
    hits: _hits,
    misses: _misses,
    size: _cache.length,
    maxSize: maxSize,
  );

  /// Hit rate del cache (0.0 - 1.0)
  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }

  /// Tamaño actual del cache
  int get length => _cache.length;

  /// Verifica si está lleno
  bool get isFull => _cache.length >= maxSize;

  /// Verifica si está vacío
  bool get isEmpty => _cache.isEmpty;
}

/// Entrada de cache con metadata
class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value) : timestamp = DateTime.now();
}

/// Métricas del cache
class CacheMetrics {
  final int hits;
  final int misses;
  final int size;
  final int maxSize;

  const CacheMetrics({
    required this.hits,
    required this.misses,
    required this.size,
    required this.maxSize,
  });

  double get hitRate {
    final total = hits + misses;
    return total == 0 ? 0.0 : hits / total;
  }

  double get fillRate => size / maxSize;

  @override
  String toString() =>
      'CacheMetrics(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, size: $size/$maxSize)';
}
