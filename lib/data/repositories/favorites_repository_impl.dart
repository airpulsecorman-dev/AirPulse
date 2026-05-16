import 'dart:io';
import '../../domain/entities/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../models/favorite_song_model.dart';
import '../sources/local/favorites_database.dart';

/// Implementación profesional del repositorio de favoritos con SQLite
///
/// Características:
/// - Persistencia local robusta con SQLite
/// - Validación automática de archivos eliminados
/// - Cache en memoria para optimizar lecturas frecuentes
/// - Manejo de errores exhaustivo
/// - Limpieza automática de favoritos rotos
/// - Operaciones atómicas y transaccionales
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesDatabase _database;

  // Cache en memoria para reducir consultas a SQLite
  final Map<String, List<Song>> _cache = {};
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 5);

  FavoritesRepositoryImpl(this._database);

  /// Verifica si el cache es válido
  bool get _isCacheValid {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) <
        _cacheValidityDuration;
  }

  /// Invalida el cache para forzar recarga desde SQLite
  void _invalidateCache(String userId) {
    _cache.remove(userId);
    _lastCacheUpdate = null;
  }

  @override
  Future<List<Song>> getFavorites(String userId) async {
    try {
      // Intenta usar cache si es válido
      if (_isCacheValid && _cache.containsKey(userId)) {
        return _cache[userId]!;
      }

      // Obtiene favoritos desde SQLite
      final favoriteMaps = await _database.getFavoritesByUserId(userId);

      // Convierte a modelos y luego a entidades
      final favoriteModels = favoriteMaps
          .map((map) => FavoriteSongModel.fromMap(map))
          .toList();

      // Valida que los archivos existan antes de retornar
      final validFavorites = await _validateFavorites(favoriteModels, userId);

      // Convierte modelos a entidades Song
      final songs = validFavorites.toSongEntities();

      // Actualiza cache
      _cache[userId] = songs;
      _lastCacheUpdate = DateTime.now();

      return songs;
    } catch (e) {
      throw RepositoryException('Error al obtener favoritos: $e');
    }
  }

  @override
  Future<void> addFavorite(String userId, Song song) async {
    try {
      // Validación previa: verifica que el archivo exista
      if (!await _database.validateFilePath(song.filePath)) {
        throw RepositoryException(
          'No se puede agregar a favoritos: el archivo no existe en ${song.filePath}',
        );
      }

      // Verifica si ya es favorito para evitar duplicados
      final isAlreadyFavorite = await _database.isFavorite(userId, song.id);
      if (isAlreadyFavorite) {
        return; // Ya está en favoritos, no hace nada
      }

      // Convierte Song a modelo de favorito
      final favoriteModel = FavoriteSongModel.fromSongEntity(song, userId);

      // Valida el modelo antes de insertar
      if (!favoriteModel.isValid()) {
        throw RepositoryException('Datos del favorito inválidos');
      }

      // Inserta en SQLite
      await _database.insertFavorite(favoriteModel.toMap());

      // Invalida cache para forzar recarga
      _invalidateCache(userId);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Error al agregar favorito: $e');
    }
  }

  @override
  Future<void> removeFavorite(String userId, String songId) async {
    try {
      // Elimina de SQLite
      final deletedRows = await _database.deleteFavorite(userId, songId);

      if (deletedRows == 0) {
        // No se encontró el favorito, pero no es un error crítico
        return;
      }

      // Invalida cache
      _invalidateCache(userId);
    } catch (e) {
      throw RepositoryException('Error al eliminar favorito: $e');
    }
  }

  @override
  Future<bool> isFavorite(String userId, String songId) async {
    try {
      // Primero intenta usar cache si está disponible
      if (_isCacheValid && _cache.containsKey(userId)) {
        return _cache[userId]!.any((song) => song.id == songId);
      }

      // Si no hay cache, consulta SQLite
      return await _database.isFavorite(userId, songId);
    } catch (e) {
      throw RepositoryException('Error al verificar favorito: $e');
    }
  }

  /// Valida que los archivos de las canciones favoritas existan
  ///
  /// Elimina automáticamente de la base de datos los favoritos
  /// cuyos archivos ya no existen en el sistema de archivos
  ///
  /// Returns: Lista de favoritos válidos (archivos existentes)
  Future<List<FavoriteSongModel>> _validateFavorites(
    List<FavoriteSongModel> favorites,
    String userId,
  ) async {
    final validFavorites = <FavoriteSongModel>[];

    for (final favorite in favorites) {
      final file = File(favorite.filePath);

      if (await file.exists()) {
        // Archivo existe, es válido
        validFavorites.add(favorite);
      } else {
        // Archivo no existe, eliminar de la base de datos
        try {
          await _database.deleteFavorite(userId, favorite.songId);
        } catch (e) {
          // Log error pero continúa con la validación
          print('Error al eliminar favorito inválido ${favorite.songId}: $e');
        }
      }
    }

    return validFavorites;
  }

  /// Limpia manualmente favoritos con archivos inexistentes
  ///
  /// Útil para ejecutar periódicamente o en el inicio de la app
  /// Returns: Número de favoritos eliminados
  @override
  Future<int> cleanInvalidFavorites(String userId) async {
    try {
      final deletedCount = await _database.cleanInvalidFavorites(userId);

      if (deletedCount > 0) {
        // Invalida cache si se eliminaron favoritos
        _invalidateCache(userId);
      }

      return deletedCount;
    } catch (e) {
      throw RepositoryException('Error al limpiar favoritos inválidos: $e');
    }
  }

  /// Elimina todos los favoritos de un usuario
  ///
  /// Útil para cerrar sesión o resetear datos
  @override
  Future<void> clearAllFavorites(String userId) async {
    try {
      await _database.deleteAllFavorites(userId);
      _invalidateCache(userId);
    } catch (e) {
      throw RepositoryException('Error al limpiar todos los favoritos: $e');
    }
  }

  /// Obtiene el número total de favoritos sin cargar todos los datos
  ///
  /// Optimizado con COUNT(*) en SQLite
  @override
  Future<int> getFavoritesCount(String userId) async {
    try {
      return await _database.getFavoritesCount(userId);
    } catch (e) {
      throw RepositoryException('Error al contar favoritos: $e');
    }
  }

  /// Busca favoritos por texto
  ///
  /// Útil para implementar búsqueda en la UI
  @override
  Future<List<Song>> searchFavorites(String userId, String query) async {
    try {
      if (query.trim().isEmpty) {
        return getFavorites(userId);
      }

      final resultMaps = await _database.searchFavorites(userId, query);

      final models = resultMaps
          .map((map) => FavoriteSongModel.fromMap(map))
          .toList();

      final validModels = await _validateFavorites(models, userId);

      return validModels.toSongEntities();
    } catch (e) {
      throw RepositoryException('Error al buscar favoritos: $e');
    }
  }

  /// Obtiene estadísticas de favoritos
  ///
  /// Información útil para mostrar en la UI o debugging
  @override
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      return await _database.getDatabaseStats(userId);
    } catch (e) {
      throw RepositoryException('Error al obtener estadísticas: $e');
    }
  }

  /// Limpia el cache manualmente
  ///
  /// Útil cuando se sabe que los datos han cambiado externamente
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }
}

/// Excepción personalizada para errores del repositorio
class RepositoryException implements Exception {
  final String message;

  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}
