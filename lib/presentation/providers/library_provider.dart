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
  bool _permissionsRequested = false;
  String? _error;
  String _searchQuery = '';

  LibraryProvider(this._libraryService);

  List<Song> get songs => _searchQuery.isEmpty
      ? _songs
      : _songs
          .where((s) =>
              s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.artist.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

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
      _songs = await _libraryService.getAllSongs();
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final playlist = await _libraryService.createPlaylist(name);
    _playlists = [..._playlists, playlist];
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _libraryService.addSongToPlaylist(playlistId, song);
    await _refreshPlaylists();
  }

  Future<void> addSongsFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );
    if (result == null || result.files.isEmpty) return;

    const uuid = Uuid();
    final newSongs = result.files
        .where((f) => f.path != null)
        .map((f) {
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
        })
        .toList();

    _songs = [..._songs, ...newSongs];
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _libraryService.deletePlaylist(playlistId);
    _playlists = _playlists.where((p) => p.id != playlistId).toList();
    notifyListeners();
  }

  Future<void> _refreshPlaylists() async {
    _playlists = await _libraryService.getAllPlaylists();
    notifyListeners();
  }
}
