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
  String? _error;
  bool _disposed = false;
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
  String get searchQuery => _searchQuery;

  Future<void> initialize() async {
    await _libraryService.requestPermissions();
    if (_disposed) return;
    await _refreshAll();
  }

  Future<void> refreshAll() async {
    if (_disposed) return;
    if (_isLoading) {
      _refreshPending = true;
      _pendingRefreshCompleter ??= Completer<void>();
      return _pendingRefreshCompleter!.future;
    }
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    do {
      _refreshPending = false;
      _error = null;
      try {
        final songs = await _libraryService.getAllSongs();
        if (_disposed) break;
        _allSongs = songs;
        final albums = await _libraryService.getAllAlbums(_allSongs);
        if (_disposed) break;
        _albums = albums;
        final artists = await _libraryService.getAllArtists(_allSongs);
        if (_disposed) break;
        _artists = artists;
        final playlists = await _libraryService.getAllPlaylists();
        if (_disposed) break;
        _playlists = playlists;
      } catch (e) {
        if (!_disposed) _error = e.toString();
      }
    } while (_refreshPending);

    _isLoading = false;
    final pendingCompleter = _pendingRefreshCompleter;
    _pendingRefreshCompleter = null;
    pendingCompleter?.complete();
    if (!_disposed) notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
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
    _isLoading = false;
    _refreshPending = false;
    final pendingCompleter = _pendingRefreshCompleter;
    _pendingRefreshCompleter = null;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete();
    }
    super.dispose();
  }
}
