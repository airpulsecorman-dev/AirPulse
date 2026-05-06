import '../entities/song.dart';
import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/playlist.dart';

abstract class LibraryRepository {
  Future<List<Song>> getAllSongs();
  Future<List<Album>> getAllAlbums();
  Future<List<Artist>> getAllArtists();
  Future<List<Playlist>> getAllPlaylists();
  Future<List<Song>> searchSongs(String query);
  Future<Song?> getSongById(String id);
  Future<Playlist> createPlaylist(String name);
  Future<void> addSongToPlaylist(String playlistId, Song song);
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
  Future<void> deletePlaylist(String playlistId);
  Future<void> deleteSongsFromDevice(List<Song> songs);
  Stream<List<Song>> watchSongs();
}
