import 'dart:async';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/song.dart';
import '../../models/song_model.dart' as app_models;

class LibraryLocalSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermissions() async {
    // Usar permission_handler directamente para evitar el crash de
    // on_audio_query cuando el PluginProvider no está inicializado
    // al recibir el resultado del sistema Android.
    PermissionStatus status;
    if (await Permission.audio.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.audio.request();
      if (!status.isGranted) {
        // Fallback para Android < 13 donde el permiso es READ_EXTERNAL_STORAGE
        status = await Permission.storage.request();
      }
    }
    return status.isGranted;
  }

  Future<List<Song>> fetchSongs() async {
    final hasPermission =
        await Permission.audio.isGranted || await Permission.storage.isGranted;
    if (!hasPermission) {
      return [];
    }
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return songs.where(_isRealMusic).map(_mapToSong).toList();
  }

  bool _isRealMusic(SongModel song) {
    final path = song.data.toLowerCase();
    // Excluir audios de WhatsApp que no sean MP3 reales
    final isWhatsAppAudio = path.contains('whatsapp') && !path.endsWith('.mp3');
    return !isWhatsAppAudio;
  }

  Future<List<Song>> searchSongs(String query) async {
    final all = await fetchSongs();
    final q = query.toLowerCase();
    return all
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q),
        )
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
