import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../domain/entities/song.dart';
import '../domain/entities/album.dart';
import '../domain/entities/artist.dart';
import 'library_service.dart';
import 'system_volume_service.dart';

/// Handler que expone los controles del reproductor al sistema operativo:
/// pantalla de bloqueo, notificación de reproducción, Bluetooth y auriculares.
class AirPulseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final LibraryService _libraryService = LibraryService();
  final Map<String, BehaviorSubject<Map<String, dynamic>>> _childrenSubjects =
      {};
  List<Song> _catalogSongs = [];
  void Function(List<Song> songs, int startIndex)? _onAndroidAutoQueue;
  bool _sessionConfigured = false;
  Timer? _positionTimer;
  Timer? _volumeSyncTimer;
  late final StreamController<double> _volumeController;
  double _lastKnownVolume = 1.0;
  late final SystemVolumeService _systemVolumeService;
  StreamSubscription? _systemVolumeSub;

  AirPulseAudioHandler() {
    _volumeController = StreamController<double>.broadcast();
    _systemVolumeService = SystemVolumeService();
    _configureAudioSession();
    _listenToPlaybackEvents();
    _listenToIndexChanges();
    _startPositionTimer();
    _startVolumeSyncTimer();
    _listenToSystemVolume();
  }

  // ─── Timer periódico para actualizar posición en la notificación ──────────

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_player.playing) {
        playbackState.add(
          playbackState.value.copyWith(
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
          ),
        );
      }
    });
  }

  // ─── Timer periódico para sincronizar volumen del sistema ────────────────

  void _startVolumeSyncTimer() {
    // Polling cada 100ms para detectar cambios de volumen del sistema
    _volumeSyncTimer = Timer.periodic(const Duration(milliseconds: 100), (
      _,
    ) async {
      try {
        final currentVolume = _player.volume;
        // Usar un threshold pequeño para detectar cambios
        if ((currentVolume - _lastKnownVolume).abs() > 0.005) {
          _lastKnownVolume = currentVolume;
          _volumeController.add(currentVolume);
        }
      } catch (_) {
        // Ignorar errores en polling
      }
    });
  }

  // ─── Configuración de sesión de audio ───────────────────────────────────

  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  }

  // ─── Sincronización con volumen del sistema ──────────────────────────────

  void _listenToSystemVolume() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _systemVolumeService.startListening();
      _systemVolumeSub = _systemVolumeService.volumeStream.listen((volume) {
        // Cuando el sistema cambia el volumen, actualizar el reproductor
        _lastKnownVolume = volume;
        _player.setVolume(volume);
        _volumeController.add(volume);
      });
    }
  }

  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenToIndexChanges() {
    _player.currentIndexStream.listen((index) {
      if (index != null &&
          queue.value.isNotEmpty &&
          index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  // ─── Conversión Song → MediaItem ────────────────────────────────────────

  static Future<Uri?> _resolveArtUri(String? artworkPath) async {
    if (artworkPath == null) return null;
    try {
      final src = File(artworkPath);
      if (!src.existsSync()) return null;
      // Copia el artwork a un archivo en caché accesible por el proceso de
      // notificaciones de Android, evitando el límite de 1 MB de Binder.
      // Usa un hash único del path para evitar que Android cachee la imagen anterior.
      final cacheDir = await getTemporaryDirectory();
      final hashCode = artworkPath.hashCode.toUnsigned(32).toRadixString(16);
      final dest = File('${cacheDir.path}/airpulse_art_$hashCode.jpg');
      await src.copy(dest.path);
      return Uri.file(dest.path);
    } catch (_) {
      return null;
    }
  }

  static String androidAutoSongMediaId(String songId) =>
      'song/${Uri.encodeComponent(songId)}';

  static Future<MediaItem> songToMediaItem(Song song) async {
    final artUri = await _resolveArtUri(song.artworkPath);
    return MediaItem(
      id: androidAutoSongMediaId(song.id),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      extras: {'filePath': song.filePath, 'songId': song.id, 'type': 'song'},
    );
  }

  // ─── API pública usada por AudioLocalSource ──────────────────────────────

  void _emitPlayingState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.loading,
        playing: true,
      ),
    );
  }

  Future<void> playSongDirect(Song song) async {
    await _configureAudioSession();
    final item = await songToMediaItem(song);
    mediaItem.add(item);
    queue.add([item]);
    _emitPlayingState(); // arranca el foreground service antes del stream
    await _player.setFilePath(song.filePath);
    await _player.play();
  }

  Future<void> setQueueFromSongs(List<Song> songs, {int startIndex = 0}) async {
    await _configureAudioSession();
    final items = await Future.wait(songs.map(songToMediaItem));
    queue.add(items);
    mediaItem.add(items[startIndex]);
    _emitPlayingState(); // arranca el foreground service antes del stream
    final sources = songs
        .map((s) => AudioSource.uri(Uri.file(s.filePath)))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
      preload: true,
    );
    await _player.play();
  }

  static const _rootMediaId = 'root';
  static const _songsMediaId = 'songs';
  static const _albumsMediaId = 'albums';
  static const _artistsMediaId = 'artists';

  String _stableKey(List<Song> songs, String artist, String name) {
    final seed =
        '$artist\u0000$name\u0000${songs.map((song) => song.id).toList()..sort()}';
    var hash = 0x811c9dc5;
    for (final codeUnit in seed.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _songMediaId(Song song) =>
      AirPulseAudioHandler.androidAutoSongMediaId(song.id);
  String _albumMediaId(Album album) =>
      'album/${Uri.encodeComponent(_stableKey(album.songs, album.artist, album.title))}';
  String _artistMediaId(Artist artist) =>
      'artist/${Uri.encodeComponent(_stableKey(artist.songs, artist.name, artist.name))}';

  Future<void> _loadCatalog() async {
    _catalogSongs = await _libraryService.getAllSongs();
  }

  Future<MediaItem> _catalogSongItem(
    Song song, {
    String? contextMediaId,
  }) async {
    final artUri = await _resolveArtUri(song.artworkPath);
    final extras = <String, dynamic>{
      'filePath': song.filePath,
      'songId': song.id,
      'type': 'song',
    };
    if (contextMediaId != null) {
      extras['contextMediaId'] = contextMediaId;
    }
    return MediaItem(
      id: _songMediaId(song),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      extras: extras,
    );
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    await _loadCatalog();

    if (parentMediaId == _rootMediaId) {
      return const [
        MediaItem(
          id: _songsMediaId,
          title: 'Canciones',
          playable: false,
          extras: {'type': 'category'},
        ),
        MediaItem(
          id: _albumsMediaId,
          title: 'Albumes',
          playable: false,
          extras: {'type': 'category'},
        ),
        MediaItem(
          id: _artistsMediaId,
          title: 'Artistas',
          playable: false,
          extras: {'type': 'category'},
        ),
      ];
    }

    if (parentMediaId == _songsMediaId) {
      return Future.wait(_catalogSongs.map((song) => _catalogSongItem(song)));
    }

    if (parentMediaId == _albumsMediaId) {
      final albums = await _libraryService.getAllAlbums();
      return Future.wait(
        albums.map((album) async {
          final artUri = await _resolveArtUri(
            album.songs.isNotEmpty ? album.songs.first.artworkPath : null,
          );
          return MediaItem(
            id: _albumMediaId(album),
            title: album.title,
            artist: album.artist,
            artUri: artUri,
            playable: false,
            extras: {'type': 'album', 'songCount': album.songs.length},
          );
        }),
      );
    }

    if (parentMediaId.startsWith('album/')) {
      final albums = await _libraryService.getAllAlbums();
      final album = albums.cast<Album?>().firstWhere(
        (item) => item != null && _albumMediaId(item) == parentMediaId,
        orElse: () => null,
      );
      if (album == null) return [];
      return Future.wait(
        album.songs.map(
          (song) => _catalogSongItem(song, contextMediaId: parentMediaId),
        ),
      );
    }

    if (parentMediaId == _artistsMediaId) {
      final artists = await _libraryService.getAllArtists();
      return Future.wait(
        artists.map((artist) async {
          final artUri = await _resolveArtUri(
            artist.songs.isNotEmpty ? artist.songs.first.artworkPath : null,
          );
          return MediaItem(
            id: _artistMediaId(artist),
            title: artist.name,
            artUri: artUri,
            playable: false,
            extras: {'type': 'artist', 'songCount': artist.songs.length},
          );
        }),
      );
    }

    if (parentMediaId.startsWith('artist/')) {
      final artists = await _libraryService.getAllArtists();
      final artist = artists.cast<Artist?>().firstWhere(
        (item) => item != null && _artistMediaId(item) == parentMediaId,
        orElse: () => null,
      );
      if (artist == null) return [];
      return Future.wait(
        artist.songs.map(
          (song) => _catalogSongItem(song, contextMediaId: parentMediaId),
        ),
      );
    }

    return [];
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    final subject = _childrenSubjects.putIfAbsent(
      parentMediaId,
      () => BehaviorSubject<Map<String, dynamic>>.seeded(const {
        'change': 'initial',
      }),
    );
    unawaited(
      getChildren(parentMediaId).then((_) {
        subject.add({'change': 'updated'});
      }),
    );
    return subject;
  }

  Future<Song?> _resolveSong(String mediaId) async {
    await _loadCatalog();
    if (mediaId.startsWith('song/')) {
      final id = Uri.decodeComponent(mediaId.substring('song/'.length));
      for (final song in _catalogSongs) {
        if (song.id == id) return song;
      }
      return null;
    }
    for (final song in _catalogSongs) {
      if (song.id == mediaId) return song;
    }
    return null;
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final song = await _resolveSong(mediaId);
    if (song != null) return _catalogSongItem(song);

    if (mediaId.startsWith('album/')) {
      final albums = await _libraryService.getAllAlbums();
      final album = albums.cast<Album?>().firstWhere(
        (item) => item != null && _albumMediaId(item) == mediaId,
        orElse: () => null,
      );
      if (album != null) {
        final artUri = await _resolveArtUri(
          album.songs.isNotEmpty ? album.songs.first.artworkPath : null,
        );
        return MediaItem(
          id: _albumMediaId(album),
          title: album.title,
          artist: album.artist,
          artUri: artUri,
          playable: false,
          extras: {'type': 'album', 'songCount': album.songs.length},
        );
      }
    }

    if (mediaId.startsWith('artist/')) {
      final artists = await _libraryService.getAllArtists();
      final artist = artists.cast<Artist?>().firstWhere(
        (item) => item != null && _artistMediaId(item) == mediaId,
        orElse: () => null,
      );
      if (artist != null) {
        final artUri = await _resolveArtUri(
          artist.songs.isNotEmpty ? artist.songs.first.artworkPath : null,
        );
        return MediaItem(
          id: _artistMediaId(artist),
          title: artist.name,
          artUri: artUri,
          playable: false,
          extras: {'type': 'artist', 'songCount': artist.songs.length},
        );
      }
    }

    return null;
  }

  Future<List<Song>> _contextSongs(
    Song selected,
    String? contextMediaId,
  ) async {
    if (contextMediaId != null && contextMediaId.startsWith('album/')) {
      final albums = await _libraryService.getAllAlbums();
      final album = albums.cast<Album?>().firstWhere(
        (item) => item != null && _albumMediaId(item) == contextMediaId,
        orElse: () => null,
      );
      if (album != null) return album.songs;
    }
    if (contextMediaId != null && contextMediaId.startsWith('artist/')) {
      final artists = await _libraryService.getAllArtists();
      final artist = artists.cast<Artist?>().firstWhere(
        (item) => item != null && _artistMediaId(item) == contextMediaId,
        orElse: () => null,
      );
      if (artist != null) return artist.songs;
    }

    final existingIds = queue.value
        .map((item) => item.extras?['songId'] as String?)
        .whereType<String>()
        .toList();
    if (existingIds.contains(selected.id)) {
      final songsById = <String, Song>{
        for (final song in _catalogSongs) song.id: song,
      };
      return [
        for (final id in existingIds)
          if (songsById[id] != null) songsById[id]!,
      ];
    }
    return _catalogSongs;
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final found = await _libraryService.searchSongs(query);
    return Future.wait(found.map((song) => _catalogSongItem(song)));
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final song = await _resolveSong(mediaId);
    if (song == null) return;

    final contextMediaId = extras?['contextMediaId'] as String?;
    final songs = await _contextSongs(song, contextMediaId);
    var startIndex = songs.indexWhere((item) => item.id == song.id);
    if (startIndex < 0) {
      songs.insert(0, song);
      startIndex = 0;
    }

    _onAndroidAutoQueue?.call(List<Song>.of(songs), startIndex);
    await setQueueFromSongs(songs, startIndex: startIndex);
  }

  // ─── Streams expuestos hacia AudioLocalSource ────────────────────────────

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _volumeController.stream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Future<void> setVolume(double volume) async {
    _lastKnownVolume = volume;
    _volumeController.add(volume);

    // Actualizar el volumen del sistema en Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _systemVolumeService.setVolume(volume);
    }

    return _player.setVolume(volume);
  }

  Future<void> seekTo(Duration position) => _player.seek(position);
  Future<void> pausePlayer() => _player.pause();
  Future<void> resumePlayer() => _player.play();
  Future<void> stopPlayer() => _player.stop();
  Future<void> nextTrack() => _player.seekToNext();
  Future<void> previousTrack() => _player.seekToPrevious();
  void attachAndroidAutoQueueSync(
    void Function(List<Song> songs, int startIndex) callback,
  ) {
    _onAndroidAutoQueue = callback;
  }

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  // ─── Overrides de BaseAudioHandler (controles del SO / BT) ──────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _positionTimer?.cancel();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) =>
      playFromMediaId(mediaItem.id, mediaItem.extras);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode != AudioServiceShuffleMode.none,
    );
  }

  void disposePlayer() {
    for (final subject in _childrenSubjects.values) {
      subject.close();
    }
    _childrenSubjects.clear();
    _positionTimer?.cancel();
    _volumeSyncTimer?.cancel();
    _systemVolumeSub?.cancel();
    _systemVolumeService.stopListening();
    _systemVolumeService.dispose();
    _volumeController.close();
    _player.dispose();
  }
}
