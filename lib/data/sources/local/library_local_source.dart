import 'dart:async';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../domain/entities/song.dart';
import '../../models/song_model.dart' as app_models;

class LibraryLocalSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermissions() async {
    return await _audioQuery.permissionsRequest();
  }

  Future<List<Song>> fetchSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return songs.map(_mapToSong).toList();
  }

  Future<List<Song>> searchSongs(String query) async {
    final all = await fetchSongs();
    final q = query.toLowerCase();
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
        .toList();
  }

  Song _mapToSong(SongModel audioSong) {
    return app_models.SongModel(
      id: audioSong.id.toString(),
      title: audioSong.title,
      artist: audioSong.artist ?? 'Unknown',
      album: audioSong.album ?? 'Unknown',
      filePath: audioSong.data,
      duration: Duration(milliseconds: audioSong.duration ?? 0),
      trackNumber: audioSong.track ?? 0,
    );
  }
}
