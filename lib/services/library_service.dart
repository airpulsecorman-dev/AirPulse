import '../domain/entities/song.dart';
import '../domain/entities/album.dart';
import '../domain/entities/artist.dart';
import '../domain/entities/playlist.dart';
import '../data/repositories/library_repository_impl.dart';
import '../data/sources/local/library_local_source.dart';

class LibraryService {
  final LibraryRepositoryImpl _repo =
      LibraryRepositoryImpl(LibraryLocalSource());

  Future<bool> requestPermissions() =>
      LibraryLocalSource().requestPermissions();

  Future<List<Song>> getAllSongs() => _repo.getAllSongs();
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
