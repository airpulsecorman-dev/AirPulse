import 'dart:async';
import 'dart:io';
import 'dart:developer' show log;
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/song.dart';
import '../../models/song_model.dart' as app_models;

class LibraryLocalSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const _audioExtensions = {
    '.mpeg',
    ' .mp3',
    '.flac',
    '.aac',
    '.m4a',
    '.wav',
    '.ogg',
    '.opus',
    '.wma',
    '.aiff',
    '.aif',
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
    // En macOS sandbox, HOME apunta al contenedor de la app.
    // Usamos USER para construir el home real del usuario.
    final user = Platform.environment['USER'] ?? '';
    final home = user.isNotEmpty
        ? '/Users/$user'
        : (Platform.environment['HOME'] ?? '');
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
      final exists = await dir.exists();
      log('[AirPulse] Carpeta $path existe: $exists');
      if (exists) searchDirs.add(dir);
    }

    // También buscar en carpetas de Documents/app si hay algo
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      log('[AirPulse] App docs: ${appDocs.path}');
      if (await appDocs.exists()) searchDirs.add(appDocs);
    } catch (e) {
      log('[AirPulse] Error obteniendo appDocs: $e');
    }

    final songs = <Song>[];
    for (final dir in searchDirs) {
      final before = songs.length;
      await _scanDirectory(dir, songs);
      log('[AirPulse] ${songs.length - before} canciones en ${dir.path}');
    }
    log('[AirPulse] Total canciones encontradas: ${songs.length}');
    return songs;
  }

  Future<void> _scanDirectory(Directory dir, List<Song> results) async {
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final ext = _extension(entity.path);
          if (_audioExtensions.contains(ext)) {
            results.add(await _mapFileToSong(entity));
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

  Future<Song> _mapFileToSong(File file) async {
    final name = file.uri.pathSegments.last;
    final ext = _extension(name);
    String title = name.length > ext.length
        ? name.substring(0, name.length - ext.length)
        : name;
    String artist = 'Unknown';
    String album = 'Unknown';
    Duration duration = Duration.zero;
    String? artworkPath;
    final stat = file.statSync();

    try {
      final metadata = await readMetadata(file, getImage: true);
      if (metadata.title != null && metadata.title!.isNotEmpty) {
        title = metadata.title!;
      }
      if (metadata.artist != null && metadata.artist!.isNotEmpty) {
        artist = metadata.artist!;
      }
      if (metadata.album != null && metadata.album!.isNotEmpty) {
        album = metadata.album!;
      }
      if (metadata.duration != null) {
        duration = metadata.duration!;
      }
      // Guardar artwork en caché si existe
      if (metadata.pictures.isNotEmpty) {
        final pic = metadata.pictures.first;
        final cacheDir = await getTemporaryDirectory();
        final artFile = File(
          '${cacheDir.path}/${file.path.hashCode}.jpg',
        );
        if (!await artFile.exists()) {
          await artFile.writeAsBytes(pic.bytes);
        }
        artworkPath = artFile.path;
      }
    } catch (e) {
      // Si no se pueden leer los metadatos, usar el nombre del archivo
    }

    return app_models.SongModel(
      id: file.path.hashCode.toString(),
      title: title,
      artist: artist,
      album: album,
      filePath: file.path,
      duration: duration,
      dateAdded: stat.modified,
      artworkPath: artworkPath,
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
          await Permission.audio.isGranted ||
          await Permission.storage.isGranted;
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
