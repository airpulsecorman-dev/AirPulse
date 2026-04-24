import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../services/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _audioService;

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;
  List<Song> _queue = [];

  AudioProvider(this._audioService) {
    _listenToStreams();
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  double get volume => _volume;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  List<Song> get queue => _queue;

  void _listenToStreams() {
    _audioService.currentSongStream.listen((song) {
      _currentSong = song;
      notifyListeners();
    });
    _audioService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
    _audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioService.volumeStream.listen((vol) {
      _volume = vol;
      notifyListeners();
    });
    _audioService.queueStream.listen((q) {
      _queue = q;
      notifyListeners();
    });
  }

  Future<void> play(Song song, {List<Song>? queue, int? index}) =>
      _audioService.playSong(song, queue: queue, index: index);
  Future<void> pause() => _audioService.pause();
  Future<void> resume() => _audioService.resume();
  Future<void> next() => _audioService.next();
  Future<void> previous() => _audioService.previous();
  Future<void> seek(Duration position) => _audioService.seek(position);
  Future<void> setVolume(double vol) => _audioService.setVolume(vol);
  Future<void> setRepeatMode(RepeatMode mode) =>
      _audioService.setRepeatMode(mode);
  Future<void> toggleShuffle() => _audioService.toggleShuffle();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
