import 'dart:async';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/library_repository.dart';
import '../models/playlist_model.dart';
import '../sources/local/library_local_source.dart';
import 'package:uuid/uuid.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalSource _localSource;
  final _songStreamController = StreamController<List<Song>>.broadcast();
  final List<PlaylistModel> _playlists = [];
  static const _uuid = Uuid();

  LibraryRepositoryImpl(this._localSource);

  @override
  Future<List<Song>> getAllSongs() async {
    final songs = await _localSource.fetchSongs();
    _songStreamController.add(songs);
    return songs;
  }

  @override
  Future<List<Album>> getAllAlbums() async {
    final songs = await getAllSongs();
    final albumMap = <String, List<Song>>{};
    for (final song in songs) {
      albumMap.putIfAbsent(song.album, () => []).add(song);
    }
    return albumMap.entries
        .map((e) => Album(
              id: e.key,
              title: e.key,
              artist: e.value.first.artist,
              songs: e.value,
            ))
        .toList();
  }

  @override
  Future<List<Artist>> getAllArtists() async {
    final songs = await getAllSongs();
    final artistMap = <String, List<Song>>{};
    for (final song in songs) {
      artistMap.putIfAbsent(song.artist, () => []).add(song);
    }
    return artistMap.entries
        .map((e) => Artist(id: e.key, name: e.key, songs: e.value))
        .toList();
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async => List.from(_playlists);

  @override
  Future<List<Song>> searchSongs(String query) =>
      _localSource.searchSongs(query);

  @override
  Future<Song?> getSongById(String id) async {
    final songs = await getAllSongs();
    try {
      return songs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Playlist> createPlaylist(String name) async {
    final playlist = PlaylistModel(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    return playlist;
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final updated = _playlists[idx].copyWith(
        songs: [..._playlists[idx].songs, song],
      );
      _playlists[idx] = updated as PlaylistModel;
    }
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final updated = _playlists[idx].copyWith(
        songs: _playlists[idx].songs.where((s) => s.id != songId).toList(),
      );
      _playlists[idx] = updated as PlaylistModel;
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
  }

  @override
  Future<void> deleteSongsFromDevice(List<Song> songs) =>
      _localSource.deleteSongs(songs);

  @override
  Stream<List<Song>> watchSongs() => _songStreamController.stream;
}
