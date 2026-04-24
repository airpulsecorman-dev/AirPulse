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
  String? _error;
  String _searchQuery = '';

  List<Song> get filteredSongs {
    if (_searchQuery.isEmpty) return _allSongs;
    final q = _searchQuery.toLowerCase();
    return _allSongs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
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
    await refreshAll();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allSongs = await _libraryService.getAllSongs();
      _albums = await _libraryService.getAllAlbums();
      _artists = await _libraryService.getAllArtists();
      _playlists = await _libraryService.getAllPlaylists();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _playlists = [..._playlists, p];
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistId, Song song) async {
    await _libraryService.addSongToPlaylist(playlistId, song);
    _playlists = await _libraryService.getAllPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await _libraryService.deletePlaylist(id);
    _playlists = _playlists.where((p) => p.id != id).toList();
    notifyListeners();
  }
}
