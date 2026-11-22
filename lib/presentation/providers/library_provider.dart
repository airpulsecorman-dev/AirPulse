import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryService _libraryService;

  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  bool _refreshPending = false;
  Completer<void>? _pendingRefreshCompleter;
  bool _permissionsRequested = false;
  bool _disposed = false;
  String? _error;
  String _searchQuery = '';

  LibraryProvider(this._libraryService);

  List<Song> get songs => _searchQuery.isEmpty
      ? _songs
      : _songs
            .where(
              (s) =>
                  s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.album.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

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

  Future<void> loadLibrary() async {
    if (_disposed) return;
    if (_isLoading) {
      _refreshPending = true;
      _pendingRefreshCompleter ??= Completer<void>();
      return _pendingRefreshCompleter!.future;
    }

    await _runLoadLoop();
  }

  Future<void> _runLoadLoop() async {
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    do {
      _refreshPending = false;
      _error = null;
      try {
        if (!_permissionsRequested) {
          _permissionsRequested = true;
          await _libraryService.requestPermissions();
          if (_disposed) break;
        }
        final songs = await _libraryService.getAllSongs();
        if (_disposed) break;
        _songs = songs;
        final albums = await _libraryService.getAllAlbums(_songs);
        if (_disposed) break;
        _albums = albums;
        final artists = await _libraryService.getAllArtists(_songs);
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final playlist = await _libraryService.createPlaylist(name);
    if (_disposed) return;
    _playlists = [..._playlists, playlist];
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _libraryService.addSongToPlaylist(playlistId, song);
    if (_disposed) return;
    await _refreshPlaylists();
  }

  Future<void> addSongsFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );
    if (_disposed) return;
    if (result == null || result.files.isEmpty) return;

    const uuid = Uuid();
    final newSongs = result.files.where((f) => f.path != null).map((f) {
      final path = f.path!;
      final name = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      return Song(
        id: uuid.v4(),
        title: name,
        artist: 'Desconocido',
        album: 'Desconocido',
        filePath: path,
        duration: Duration.zero,
        dateAdded: DateTime.now(),
      );
    }).toList();

    _songs = [..._songs, ...newSongs];
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _libraryService.deletePlaylist(playlistId);
    if (_disposed) return;
    _playlists = _playlists.where((p) => p.id != playlistId).toList();
    notifyListeners();
  }

  Future<void> deleteSongs(List<String> ids) async {
    final idSet = ids.toSet();
    final toDelete = _songs.where((s) => idSet.contains(s.id)).toList();
    await _libraryService.deleteSongsFromDevice(toDelete);
    if (_disposed) return;
    _songs = _songs.where((s) => !idSet.contains(s.id)).toList();
    notifyListeners();
  }

  Future<void> _refreshPlaylists() async {
    _playlists = await _libraryService.getAllPlaylists();
    if (_disposed) return;
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
