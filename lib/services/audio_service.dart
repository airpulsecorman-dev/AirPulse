import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../domain/entities/song.dart';
import '../domain/repositories/player_repository.dart';
import '../data/sources/local/audio_local_source.dart';
import '../data/repositories/player_repository_impl.dart';
import 'audio_handler.dart';

class AudioService {
  final AudioLocalSource _source;
  late final PlayerRepository _repository;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;

  final _currentSongController = StreamController<Song?>.broadcast();
  final _queueController = StreamController<List<Song>>.broadcast();

  AudioService(AirPulseAudioHandler handler)
      : _source = AudioLocalSource(handler) {
    _repository = PlayerRepositoryImpl(_source);
    _listenToPlayerState();
    _listenToCurrentIndex();
  }

  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<bool> get isPlayingStream => _source.isPlayingStream;
  Stream<Duration> get positionStream => _source.positionStream;
  Stream<double> get volumeStream => _source.volumeStream;
  Stream<PlayerState> get playerStateStream => _source.playerStateStream;

  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    // Notificar la canción actual ANTES del await para que la navegación
    // a /player la encuentre disponible de inmediato en AudioProvider.
    _currentSong = song;
    _currentSongController.add(_currentSong);

    if (queue != null) {
      _queue = queue;
      _currentIndex = index ?? 0;
      _queueController.add(_queue);
      // setQueue ya inicia la reproducción internamente
      await _repository.setQueue(queue, startIndex: _currentIndex);
    } else {
      await _repository.play(song);
    }
  }

  Future<void> pause() => _repository.pause();
  Future<void> resume() => _repository.resume();
  Future<void> stop() => _repository.stop();
  Future<void> seek(Duration position) => _repository.seek(position);
  Future<void> setVolume(double volume) => _repository.setVolume(volume);

  Future<void> next() async {
    await _repository.next();
  }

  Future<void> previous() async {
    await _repository.previous();
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    await _repository.setRepeatMode(mode);
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await _repository.toggleShuffle();
  }

  void _listenToPlayerState() {
    _source.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  void _listenToCurrentIndex() {
    _source.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length && index != _currentIndex) {
        _currentIndex = index;
        _currentSong = _queue[index];
        _currentSongController.add(_currentSong);
      }
    });
  }

  void _handleTrackCompletion() {
    if (_repeatMode == RepeatMode.one && _currentSong != null) {
      playSong(_currentSong!);
    }
  }

  Map<String, dynamic> toJsonState({
    bool? isPlaying,
    int positionMs = 0,
  }) {
    return {
      'type': 'player_state',
      'songId': _currentSong?.id,
      'songTitle': _currentSong?.title,
      'songArtist': _currentSong?.artist,
      'songAlbum': _currentSong?.album,
      'isPlaying': isPlaying ?? false,
      'positionMs': positionMs,
      'repeatMode': _repeatMode.name,
      'shuffleEnabled': _shuffleEnabled,
      'currentIndex': _currentIndex,
    };
  }

  void dispose() {
    _source.dispose();
    _currentSongController.close();
    _queueController.close();
  }
}
