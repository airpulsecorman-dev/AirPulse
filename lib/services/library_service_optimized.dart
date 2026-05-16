/// 🎵 AirPulse Library Service - OPTIMIZADO
///
/// Servicio optimizado con source avanzado.
///
/// @author AirPulse Performance Team
/// @enterprise
/// @production
library;

import '../domain/entities/song.dart';
import '../domain/entities/album.dart';
import '../domain/entities/artist.dart';
import '../domain/entities/playlist.dart';
import '../data/repositories/library_repository_impl.dart';
import '../data/sources/local/library_local_source.dart';
import '../data/sources/local/library_local_source_optimized.dart';

class LibraryServiceOptimized {
  final LibraryRepositoryImpl _repo;
  final LibraryLocalSourceOptimized _source;

  LibraryServiceOptimized()
    : _source = LibraryLocalSourceOptimized(),
      _repo = LibraryRepositoryImpl(LibraryLocalSource()) {
    _source.initialize();
  }

  Future<bool> requestPermissions() => _source.requestPermissions();

  /// 🚀 Obtiene todas las canciones con progress tracking
  Future<List<Song>> getAllSongs({
    void Function(int current, int total)? onProgress,
  }) async {
    return _source.fetchSongs(onProgress: onProgress);
  }

  Future<List<Album>> getAllAlbums() => _repo.getAllAlbums();
  Future<List<Artist>> getAllArtists() => _repo.getAllArtists();
  Future<List<Playlist>> getAllPlaylists() => _repo.getAllPlaylists();
  Future<List<Song>> searchSongs(String query) => _repo.searchSongs(query);
  Future<Playlist> createPlaylist(String name) => _repo.createPlaylist(name);

  Future<void> addSongToPlaylist(String playlistId, Song song) =>
      _repo.addSongToPlaylist(playlistId, song);

  Future<void> removeSongFromPlaylist(String playlistId, String songId) =>
      _repo.removeSongFromPlaylist(playlistId, songId);

  Future<void> deletePlaylist(String playlistId) =>
      _repo.deletePlaylist(playlistId);

  Future<void> deleteSongsFromDevice(List<Song> songs) =>
      _repo.deleteSongsFromDevice(songs);

  Stream<List<Song>> watchSongs() => _repo.watchSongs();
}
