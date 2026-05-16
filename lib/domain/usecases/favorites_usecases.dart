import '../../domain/entities/song.dart';
import '../repositories/favorites_repository.dart';

/// Caso de uso: Obtener lista de canciones favoritas
///
/// Retorna todas las canciones favoritas de un usuario ordenadas por fecha
/// de agregado (más recientes primero). Solo incluye favoritos válidos
/// (archivos que aún existen en el sistema).
class GetFavoritesUseCase {
  final FavoritesRepository _repo;

  GetFavoritesUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// Returns: Lista de canciones favoritas válidas
  Future<List<Song>> call(String userId) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    return await _repo.getFavorites(userId);
  }
}

/// Caso de uso: Agregar canción a favoritos
///
/// Valida que el archivo exista antes de agregarlo a favoritos.
/// Si la canción ya está en favoritos, no hace nada (operación idempotente).
class AddFavoriteUseCase {
  final FavoritesRepository _repo;

  AddFavoriteUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// [song] - Canción a agregar a favoritos
  /// Throws: UseCaseException si hay errores de validación
  Future<void> call(String userId, Song song) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    if (song.filePath.isEmpty) {
      throw UseCaseException('La ruta del archivo no puede estar vacía');
    }

    await _repo.addFavorite(userId, song);
  }
}

/// Caso de uso: Eliminar canción de favoritos
///
/// Elimina una canción de la lista de favoritos del usuario.
/// Si la canción no está en favoritos, no hace nada (operación idempotente).
class RemoveFavoriteUseCase {
  final FavoritesRepository _repo;

  RemoveFavoriteUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// [songId] - ID de la canción a eliminar
  Future<void> call(String userId, String songId) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    if (songId.isEmpty) {
      throw UseCaseException('El ID de la canción no puede estar vacío');
    }

    await _repo.removeFavorite(userId, songId);
  }
}

/// Caso de uso: Verificar si una canción es favorita
///
/// Consulta eficiente que verifica si una canción específica
/// está en la lista de favoritos del usuario.
class IsFavoriteUseCase {
  final FavoritesRepository _repo;

  IsFavoriteUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// [songId] - ID de la canción a verificar
  /// Returns: true si es favorita, false en caso contrario
  Future<bool> call(String userId, String songId) async {
    if (userId.isEmpty || songId.isEmpty) {
      return false;
    }

    return await _repo.isFavorite(userId, songId);
  }
}

/// Caso de uso: Alternar estado de favorito (toggle)
///
/// Si la canción es favorita, la elimina.
/// Si no es favorita, la agrega.
/// Operación atómica y conveniente para botones de favorito en la UI.
class ToggleFavoriteUseCase {
  final FavoritesRepository _repo;

  ToggleFavoriteUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// [song] - Canción a alternar
  /// Returns: true si ahora es favorita, false si se eliminó
  Future<bool> call(String userId, Song song) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    final isFavorite = await _repo.isFavorite(userId, song.id);

    if (isFavorite) {
      await _repo.removeFavorite(userId, song.id);
      return false;
    } else {
      await _repo.addFavorite(userId, song);
      return true;
    }
  }
}

/// Caso de uso: Limpiar favoritos inválidos
///
/// Elimina automáticamente favoritos cuyos archivos ya no existen.
/// Útil para ejecutar al iniciar la aplicación o periódicamente.
class CleanInvalidFavoritesUseCase {
  final FavoritesRepository _repo;

  CleanInvalidFavoritesUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// Returns: Número de favoritos eliminados
  Future<int> call(String userId) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    return await _repo.cleanInvalidFavorites(userId);
  }
}

/// Caso de uso: Obtener cantidad de favoritos
///
/// Consulta optimizada que retorna solo el número total de favoritos
/// sin cargar todos los datos.
class GetFavoritesCountUseCase {
  final FavoritesRepository _repo;

  GetFavoritesCountUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// Returns: Número total de favoritos
  Future<int> call(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }

    return await _repo.getFavoritesCount(userId);
  }
}

/// Caso de uso: Buscar en favoritos
///
/// Busca canciones favoritas por título, artista o álbum.
class SearchFavoritesUseCase {
  final FavoritesRepository _repo;

  SearchFavoritesUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// [query] - Texto de búsqueda
  /// Returns: Lista de favoritos que coinciden con la búsqueda
  Future<List<Song>> call(String userId, String query) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    return await _repo.searchFavorites(userId, query);
  }
}

/// Caso de uso: Limpiar todos los favoritos
///
/// Elimina completamente todos los favoritos de un usuario.
/// Útil para cerrar sesión o resetear datos.
class ClearAllFavoritesUseCase {
  final FavoritesRepository _repo;

  ClearAllFavoritesUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  Future<void> call(String userId) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    await _repo.clearAllFavorites(userId);
  }
}

/// Caso de uso: Obtener estadísticas de favoritos
///
/// Retorna información útil sobre los favoritos del usuario:
/// - Número total de favoritos
/// - Tamaño de la base de datos
/// - Ruta de almacenamiento
class GetFavoritesStatisticsUseCase {
  final FavoritesRepository _repo;

  GetFavoritesStatisticsUseCase(this._repo);

  /// Ejecuta el caso de uso
  ///
  /// [userId] - ID del usuario autenticado
  /// Returns: Mapa con estadísticas
  Future<Map<String, dynamic>> call(String userId) async {
    if (userId.isEmpty) {
      throw UseCaseException('El ID de usuario no puede estar vacío');
    }

    return await _repo.getStatistics(userId);
  }
}

/// Excepción personalizada para errores de use cases
class UseCaseException implements Exception {
  final String message;

  UseCaseException(this.message);

  @override
  String toString() => 'UseCaseException: $message';
}
