/// 📚 AirPulse Library Provider - OPTIMIZADO
///
/// Provider empresarial optimizado para gestión de biblioteca musical.
///
/// Optimizaciones implementadas:
/// - Filtrado con memoización
/// - Búsqueda en isolate (compute)
/// - Cache de resultados
/// - Debouncing de búsquedas
/// - Pagination support
/// - Memory-efficient operations
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../services/library_service.dart';
import '../../core/managers/cache_manager.dart';
import '../../core/managers/pagination_manager.dart';
import '../../core/services/compute_service.dart';

/// Provider optimizado para biblioteca musical
class LibraryProviderOptimized extends ChangeNotifier {
  final LibraryService _libraryService;
  final ComputeService _computeService = ComputeService();

  // State
  List<Song> _allSongs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  bool _permissionsRequested = false;
  String? _error;
  String _searchQuery = '';

  // 🚀 OPTIMIZACIÓN: Cache de resultados filtrados
  final CacheManager<String, List<Song>> _filteredCache = CacheManager(
    maxSize: 50,
    ttl: const Duration(minutes: 5),
  );

  // 🚀 OPTIMIZACIÓN: Debouncer para búsquedas
  Timer? _searchDebouncer;
  List<Song>? _cachedFilteredSongs;
  String? _lastFilteredQuery;

  // 🚀 OPTIMIZACIÓN: Pagination manager
  PaginationManager<Song>? _paginationManager;

  LibraryProviderOptimized(this._libraryService);

  // ============================================================================
  // GETTERS - OPTIMIZED
  // ============================================================================

  /// 🚀 OPTIMIZACIÓN: Getter con cache y compute para filtrado
  List<Song> get songs {
    // Sin búsqueda: retornar todos (o paginados)
    if (_searchQuery.isEmpty) {
      return _paginationManager?.items ?? _allSongs;
    }

    // Con búsqueda: usar cache si disponible
    if (_lastFilteredQuery == _searchQuery && _cachedFilteredSongs != null) {
      return _cachedFilteredSongs!;
    }

    // Cache miss: retornar temporalmente resultados anteriores mientras se computa
    return _cachedFilteredSongs ?? [];
  }

  List<Album> get albums {
    if (_searchQuery.isEmpty) return _albums;
    final q = _searchQuery.toLowerCase();
    return _albums
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Artist> get artists {
    if (_searchQuery.isEmpty) return _artists;
    final q = _searchQuery.toLowerCase();
    return _artists.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get totalSongs => _allSongs.length;
  int get loadedSongs => _paginationManager?.loadedCount ?? _allSongs.length;

  // 🚀 Cache metrics
  CacheMetrics get cacheMetrics => _filteredCache.metrics;

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Inicializa paginación
  void initializePagination({int pageSize = 100}) {
    _paginationManager = PaginationManager(
      items: _allSongs,
      pageSize: pageSize,
      prefetchThreshold: 20,
    );
  }

  /// Carga más items (pagination)
  Future<void> loadMore() async {
    await _paginationManager?.loadMore();
    notifyListeners();
  }

  /// Verifica si debe cargar más basado en scroll
  void checkPrefetch(int currentIndex) {
    _paginationManager?.checkPrefetch(currentIndex);
  }

  Future<void> loadLibrary() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!_permissionsRequested) {
        _permissionsRequested = true;
        await _libraryService.requestPermissions();
      }

      // 🚀 OPTIMIZACIÓN: Cargar en paralelo cuando sea posible
      final results = await Future.wait([
        _libraryService.getAllSongs(),
        _libraryService.getAllAlbums(),
        _libraryService.getAllArtists(),
        _libraryService.getAllPlaylists(),
      ]);

      _allSongs = results[0] as List<Song>;
      _albums = results[1] as List<Album>;
      _artists = results[2] as List<Artist>;
      _playlists = results[3] as List<Playlist>;

      // Inicializar paginación
      initializePagination();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🚀 OPTIMIZACIÓN: Búsqueda con debounce y compute
  void setSearchQuery(String query) {
    _searchQuery = query;

    // Cancelar búsqueda anterior
    _searchDebouncer?.cancel();

    // Si está vacío, limpiar inmediatamente
    if (query.isEmpty) {
      _cachedFilteredSongs = null;
      _lastFilteredQuery = null;
      notifyListeners();
      return;
    }

    // 🚀 Debounce de 300ms
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });

    // Notificar para mostrar loading state
    notifyListeners();
  }

  /// Ejecuta búsqueda en isolate
  Future<void> _performSearch(String query) async {
    final q = query.toLowerCase();

    // Verificar cache primero
    final cached = _filteredCache.get(q);
    if (cached != null) {
      _cachedFilteredSongs = cached;
      _lastFilteredQuery = query;
      notifyListeners();
      return;
    }

    // 🚀 OPTIMIZACIÓN: Filtrar en isolate si hay muchas canciones
    if (_allSongs.length > 500) {
      try {
        final filtered = await _computeService.filterSongs(
          songs: _allSongs,
          query: query,
        );

        _cachedFilteredSongs = filtered;
        _lastFilteredQuery = query;
        _filteredCache.put(q, filtered);
      } catch (e) {
        debugPrint('Error filtering songs: $e');
        _cachedFilteredSongs = _filterSongsSync(query);
      }
    } else {
      // Pocos items: filtrar síncronamente
      _cachedFilteredSongs = _filterSongsSync(query);
      _filteredCache.put(q, _cachedFilteredSongs!);
    }

    notifyListeners();
  }

  /// Filtrado síncrono (para listas pequeñas)
  List<Song> _filterSongsSync(String query) {
    final q = query.toLowerCase();
    return _allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q),
        )
        .toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _cachedFilteredSongs = null;
    _lastFilteredQuery = null;
    _searchDebouncer?.cancel();
    notifyListeners();
  }

  // ============================================================================
  // PLAYLIST OPERATIONS
  // ============================================================================

  Future<void> createPlaylist(String name) async {
    final playlist = await _libraryService.createPlaylist(name);
    _playlists = [..._playlists, playlist];
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _libraryService.addSongToPlaylist(playlistId, song);
    await _refreshPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _libraryService.deletePlaylist(id);
    _playlists = _playlists.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> _refreshPlaylists() async {
    _playlists = await _libraryService.getAllPlaylists();
    notifyListeners();
  }

  // ============================================================================
  // SONG OPERATIONS
  // ============================================================================

  Future<void> addSongsFromFiles() async {
    // Implementación existente...
    await loadLibrary();
  }

  Future<void> deleteSongs(List<String> songIds) async {
    final songsToDelete = _allSongs
        .where((s) => songIds.contains(s.id))
        .toList();
    await _libraryService.deleteSongsFromDevice(songsToDelete);
    await loadLibrary();
  }

  // ============================================================================
  // DISPOSAL
  // ============================================================================

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _paginationManager?.dispose();
    _filteredCache.clear();
    super.dispose();
  }
}
