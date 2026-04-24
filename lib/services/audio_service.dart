import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../domain/entities/song.dart';
import '../domain/repositories/player_repository.dart';
import '../data/sources/local/audio_local_source.dart';
import '../data/repositories/player_repository_impl.dart';

class AudioService {
  final AudioLocalSource _source = AudioLocalSource();
  late final PlayerRepository _repository;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;

  final _currentSongController = StreamController<Song?>.broadcast();
  final _queueController = StreamController<List<Song>>.broadcast();

  AudioService() {
    _repository = PlayerRepositoryImpl(_source);
    _listenToPlayerState();
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
    if (queue != null) {
      _queue = queue;
      _currentIndex = index ?? 0;
      _queueController.add(_queue);
      await _repository.setQueue(queue, startIndex: _currentIndex);
    } else {
      await _repository.play(song);
    }
    _currentSong = song;
    _currentSongController.add(_currentSong);
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

  void _handleTrackCompletion() {
    if (_repeatMode == RepeatMode.one && _currentSong != null) {
      playSong(_currentSong!);
    }
  }

  Map<String, dynamic> toJsonState() {
    return {
      'type': 'player_state',
      'songId': _currentSong?.id,
      'songTitle': _currentSong?.title,
      'songArtist': _currentSong?.artist,
      'isPlaying': true,
      'repeatMode': _repeatMode.name,
      'shuffleEnabled': _shuffleEnabled,
    };
  }

  void dispose() {
    _source.dispose();
    _currentSongController.close();
    _queueController.close();
  }
}
