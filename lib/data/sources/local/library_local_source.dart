import 'dart:async';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/song.dart';
import '../../models/song_model.dart' as app_models;

class LibraryLocalSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const _audioExtensions = {
    '.mp3', '.flac', '.aac', '.m4a', '.wav', '.ogg', '.opus', '.wma', '.aiff', '.aif',
  };

  Future<bool> requestPermissions() async {
    // macOS no requiere permission_handler
    if (Platform.isMacOS) return true;

    PermissionStatus status;
    if (Platform.isIOS) {
      status = await Permission.mediaLibrary.request();
    } else {
      // Android
      if (await Permission.audio.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.audio.request();
        if (!status.isGranted) {
          // Fallback para Android < 13 donde el permiso es READ_EXTERNAL_STORAGE
          status = await Permission.storage.request();
        }
      }
    }
    return status.isGranted;
  }

  /// Escanea el sistema de archivos en macOS buscando canciones.
  Future<List<Song>> _fetchSongsMacOS() async {
    final home = Platform.environment['HOME'] ?? '';
    final searchDirs = <Directory>[];

    // Carpetas comunes de música en macOS
    final candidates = [
      '$home/Music',
      '$home/Downloads',
      '$home/Desktop',
      '$home/Documents',
    ];

    for (final path in candidates) {
      final dir = Directory(path);
      if (await dir.exists()) searchDirs.add(dir);
    }

    // También buscar en carpetas de Documents/app si hay algo
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      if (await appDocs.exists()) searchDirs.add(appDocs);
    } catch (_) {}

    final songs = <Song>[];
    for (final dir in searchDirs) {
      await _scanDirectory(dir, songs);
    }
    return songs;
  }

  Future<void> _scanDirectory(Directory dir, List<Song> results) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = _extension(entity.path);
          if (_audioExtensions.contains(ext)) {
            results.add(_mapFileToSong(entity));
          }
        }
      }
    } catch (_) {
      // Ignorar directorios sin acceso
    }
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '';
    return path.substring(dot).toLowerCase();
  }

  Song _mapFileToSong(File file) {
    final name = file.uri.pathSegments.last;
    final ext = _extension(name);
    final title = name.length > ext.length ? name.substring(0, name.length - ext.length) : name;
    final stat = file.statSync();
    return app_models.SongModel(
      id: file.path.hashCode.toString(),
      title: title,
      artist: 'Unknown',
      album: 'Unknown',
      filePath: file.path,
      duration: Duration.zero,
      dateAdded: stat.modified,
    );
  }

  Future<List<Song>> fetchSongs() async {
    // on_audio_query y permission_handler no tienen soporte macOS
    if (Platform.isMacOS) return _fetchSongsMacOS();

    final bool hasPermission;
    if (Platform.isIOS) {
      hasPermission = await Permission.mediaLibrary.isGranted;
    } else {
      hasPermission =
          await Permission.audio.isGranted || await Permission.storage.isGranted;
    }
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
