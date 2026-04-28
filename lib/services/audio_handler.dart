import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/entities/song.dart';

/// Handler que expone los controles del reproductor al sistema operativo:
/// pantalla de bloqueo, notificación de reproducción, Bluetooth y auriculares.
class AirPulseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  bool _sessionConfigured = false;
  Timer? _positionTimer;

  AirPulseAudioHandler() {
    _configureAudioSession();
    _listenToPlaybackEvents();
    _listenToIndexChanges();
    _startPositionTimer();
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

  // ─── Configuración de sesión de audio ───────────────────────────────────

  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  }

  // ─── Sincronización del estado de reproducción con el SO ────────────────

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

  static Future<MediaItem> songToMediaItem(Song song) async {
    final artUri = await _resolveArtUri(song.artworkPath);
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      extras: {'filePath': song.filePath},
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

  // ─── Streams expuestos hacia AudioLocalSource ────────────────────────────

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Future<void> setVolume(double volume) => _player.setVolume(volume);
  Future<void> seekTo(Duration position) => _player.seek(position);
  Future<void> pausePlayer() => _player.pause();
  Future<void> resumePlayer() => _player.play();
  Future<void> stopPlayer() => _player.stop();
  Future<void> nextTrack() => _player.seekToNext();
  Future<void> previousTrack() => _player.seekToPrevious();

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
    _positionTimer?.cancel();
    _player.dispose();
  }
}
