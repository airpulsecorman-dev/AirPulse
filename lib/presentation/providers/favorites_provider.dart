import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/favorites_usecases.dart';

/// Provider profesional para gestión de favoritos
///
/// Características:
/// - State management reactivo con ChangeNotifier
/// - Caché en memoria para optimizar rendimiento
/// - Limpieza automática de favoritos inválidos
/// - Búsqueda en tiempo real
/// - Manejo robusto de errores
/// - Operaciones debounced para evitar consultas excesivas
class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repo;

  // Estado
  List<Song> _favorites = [];
  bool _isLoading = false;
  String? _error;
  int _count = 0;

  // Búsqueda
  List<Song> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Estado de limpieza
  bool _isCleaning = false;
  int _lastCleanedCount = 0;

  FavoritesProvider(this._repo);

  // Getters
  List<Song> get favorites => _favorites;
  List<Song> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isCleaning => _isCleaning;
  String? get error => _error;
  int get count => _count;
  int get lastCleanedCount => _lastCleanedCount;
  bool get hasError => _error != null;
  bool get isEmpty => _favorites.isEmpty;

  /// Carga los favoritos del usuario desde el repositorio
  ///
  /// Incluye limpieza automática de favoritos con archivos eliminados
  Future<void> loadFavorites(String userId, {bool cleanInvalid = true}) async {
    if (userId.isEmpty) {
      _error = 'ID de usuario inválido';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Limpia favoritos inválidos si está habilitado
      if (cleanInvalid) {
        await _cleanInvalidFavorites(userId);
      }

      // Carga favoritos
      _favorites = await GetFavoritesUseCase(_repo).call(userId);
      _count = _favorites.length;

      // Si hay búsqueda activa, actualiza resultados
      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }
    } catch (e) {
      _error = 'Error al cargar favoritos: ${e.toString()}';
      _favorites = [];
      _count = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna el estado de favorito de una canción (add/remove)
  ///
  /// Operación optimista: actualiza UI primero, luego persiste
  Future<void> toggleFavorite(String userId, Song song) async {
    if (userId.isEmpty) {
      _error = 'ID de usuario inválido';
      notifyListeners();
      return;
    }

    try {
      final isFav = isFavorite(song.id);

      // Actualización optimista de UI
      if (isFav) {
        _favorites.removeWhere((s) => s.id == song.id);
        _count = _favorites.length;
      } else {
        _favorites = [song, ..._favorites]; // Agrega al inicio
        _count = _favorites.length;
      }

      // Actualiza búsqueda si está activa
      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }

      notifyListeners();

      // Persiste cambios
      final result = await ToggleFavoriteUseCase(_repo).call(userId, song);

      // Verifica coherencia (por si hubo error)
      if (result != !isFav) {
        // Rollback: recarga desde fuente de verdad
        await loadFavorites(userId, cleanInvalid: false);
      }
    } catch (e) {
      _error = 'Error al actualizar favorito: ${e.toString()}';
      // Rollback en caso de error
      await loadFavorites(userId, cleanInvalid: false);
    }
  }

  /// Agrega una canción a favoritos
  Future<void> addFavorite(String userId, Song song) async {
    if (userId.isEmpty) return;

    try {
      // Verifica que no esté ya en favoritos
      if (isFavorite(song.id)) return;

      // Actualización optimista
      _favorites = [song, ..._favorites];
      _count = _favorites.length;

      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }

      notifyListeners();

      // Persiste
      await AddFavoriteUseCase(_repo).call(userId, song);
    } catch (e) {
      _error = 'Error al agregar favorito: ${e.toString()}';
      await loadFavorites(userId, cleanInvalid: false);
    }
  }

  /// Elimina una canción de favoritos
  Future<void> removeFavorite(String userId, String songId) async {
    if (userId.isEmpty) return;

    try {
      // Actualización optimista
      _favorites.removeWhere((s) => s.id == songId);
      _count = _favorites.length;

      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }

      notifyListeners();

      // Persiste
      await RemoveFavoriteUseCase(_repo).call(userId, songId);
    } catch (e) {
      _error = 'Error al eliminar favorito: ${e.toString()}';
      await loadFavorites(userId, cleanInvalid: false);
    }
  }

  /// Verifica si una canción es favorita (consulta local rápida)
  bool isFavorite(String songId) {
    return _favorites.any((s) => s.id == songId);
  }

  /// Busca favoritos por texto
  ///
  /// Busca en título, artista y álbum
  Future<void> searchFavorites(String userId, String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await SearchFavoritesUseCase(
        _repo,
      ).call(userId, _searchQuery);
    } catch (e) {
      _error = 'Error en búsqueda: ${e.toString()}';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Realiza búsqueda local (sin consultar repositorio)
  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      return;
    }

    final lowerQuery = _searchQuery.toLowerCase();
    _searchResults = _favorites.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Limpia la búsqueda activa
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Limpia favoritos con archivos eliminados (operación en background)
  Future<void> _cleanInvalidFavorites(String userId) async {
    try {
      _lastCleanedCount = await CleanInvalidFavoritesUseCase(
        _repo,
      ).call(userId);
    } catch (e) {
      // No es crítico, solo registra
      debugPrint('Error al limpiar favoritos inválidos: $e');
    }
  }

  /// Limpia manualmente favoritos inválidos (con feedback UI)
  Future<void> cleanInvalidFavorites(String userId) async {
    if (userId.isEmpty) return;

    _isCleaning = true;
    notifyListeners();

    try {
      _lastCleanedCount = await CleanInvalidFavoritesUseCase(
        _repo,
      ).call(userId);

      // Recarga favoritos si se eliminaron algunos
      if (_lastCleanedCount > 0) {
        await loadFavorites(userId, cleanInvalid: false);
      }
    } catch (e) {
      _error = 'Error al limpiar favoritos: ${e.toString()}';
    } finally {
      _isCleaning = false;
      notifyListeners();
    }
  }

  /// Elimina todos los favoritos del usuario
  Future<void> clearAllFavorites(String userId) async {
    if (userId.isEmpty) return;

    try {
      await ClearAllFavoritesUseCase(_repo).call(userId);
      _favorites = [];
      _count = 0;
      _searchResults = [];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar todos los favoritos: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Obtiene estadísticas de favoritos
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    if (userId.isEmpty) return {};

    try {
      return await GetFavoritesStatisticsUseCase(_repo).call(userId);
    } catch (e) {
      _error = 'Error al obtener estadísticas: ${e.toString()}';
      return {};
    }
  }

  /// Limpia el error actual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Resetea el estado completo del provider
  void clear() {
    _favorites = [];
    _searchResults = [];
    _searchQuery = '';
    _count = 0;
    _isLoading = false;
    _isSearching = false;
    _isCleaning = false;
    _error = null;
    _lastCleanedCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
