import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../services/library_service.dart';

class LibraryController extends ChangeNotifier {
  final LibraryService _libraryService;

  LibraryController(this._libraryService);

  List<Song> _allSongs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  bool _refreshPending = false;
  Completer<void>? _pendingRefreshCompleter;
  Completer<void>? _pendingLoadCompleter;
  String? _error;
  bool _disposed = false;
  bool _cancelled = false;
  bool _hasSuccessfulLoad = false;
  int _loadGeneration = 0;
  String _searchQuery = '';

  List<Song> get filteredSongs {
    if (_searchQuery.isEmpty) return _allSongs;
    final q = _searchQuery.toLowerCase();
    return _allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCancelled => _cancelled;
  String get loadStatus => _disposed && _cancelled
      ? 'cancelled'
      : _isLoading
      ? 'loading'
      : _error != null
      ? 'failed'
      : _hasSuccessfulLoad
      ? 'success'
      : 'idle';
  String get searchQuery => _searchQuery;

  Future<void> initialize() async {
    await _libraryService.requestPermissions();
    if (_disposed) return;
    await _refreshAll();
  }

  Future<void> refreshAll() {
    if (_disposed) {
      _cancelled = true;
      return Future<void>.value();
    }
    if (_isLoading) {
      _refreshPending = true;
      _pendingRefreshCompleter ??= Completer<void>();
      return _pendingRefreshCompleter!.future;
    }
    final completer = Completer<void>();
    _pendingLoadCompleter = completer;
    _refreshAll();
    return completer.future;
  }

  Future<void> _refreshAll() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _isLoading = true;
    _cancelled = false;
    _error = null;
    if (!_disposed) notifyListeners();

    do {
      if (_disposed || generation != _loadGeneration) break;
      _refreshPending = false;
      _error = null;
      try {
        final songs = await _libraryService.getAllSongs();
        if (_disposed || generation != _loadGeneration) break;
        _allSongs = songs;
        final albums = await _libraryService.getAllAlbums(_allSongs);
        if (_disposed || generation != _loadGeneration) break;
        _albums = albums;
        final artists = await _libraryService.getAllArtists(_allSongs);
        if (_disposed || generation != _loadGeneration) break;
        _artists = artists;
        final playlists = await _libraryService.getAllPlaylists();
        if (_disposed || generation != _loadGeneration) break;
        _playlists = playlists;
        if (generation == _loadGeneration && !_disposed) {
          _hasSuccessfulLoad = true;
        }
      } catch (e) {
        if (!_disposed && generation == _loadGeneration) {
          _error = e.toString();
        }
      }
    } while (_refreshPending);

    if (_disposed) {
      _cancelled = true;
      _isLoading = false;
      _completePendingRefresh();
      _completePendingLoad();
      return;
    }
    if (generation != _loadGeneration) {
      _completePendingLoad();
      return;
    }

    _isLoading = false;
    _completePendingRefresh();
    _completePendingLoad();
    if (!_disposed) notifyListeners();
  }

  void _completePendingLoad() {
    final pendingCompleter = _pendingLoadCompleter;
    _pendingLoadCompleter = null;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete();
    }
  }

  void _completePendingRefresh() {
    final pendingCompleter = _pendingRefreshCompleter;
    _pendingRefreshCompleter = null;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete();
    }
  }

  void search(String query) {
    if (_disposed) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_disposed) return;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final p = await _libraryService.createPlaylist(name);
    if (_disposed) return;
    _playlists = [..._playlists, p];
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistId, Song song) async {
    await _libraryService.addSongToPlaylist(playlistId, song);
    if (_disposed) return;
    _playlists = await _libraryService.getAllPlaylists();
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await _libraryService.deletePlaylist(id);
    if (_disposed) return;
    _playlists = _playlists.where((p) => p.id != id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelled = true;
    _isLoading = false;
    _refreshPending = false;
    _loadGeneration++;
    _completePendingRefresh();
    _completePendingLoad();
    super.dispose();
  }
}
