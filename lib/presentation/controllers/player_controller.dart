import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../services/audio_service.dart';

class PlayerController extends ChangeNotifier {
  final AudioService _audioService;

  PlayerController(this._audioService) {
    _initStreams();
  }

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;
  List<Song> _queue = [];

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  double get volume => _volume;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  List<Song> get queue => _queue;

  void _initStreams() {
    _audioService.currentSongStream.listen((s) {
      _currentSong = s;
      notifyListeners();
    });
    _audioService.isPlayingStream.listen((p) {
      _isPlaying = p;
      notifyListeners();
    });
    _audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioService.volumeStream.listen((v) {
      _volume = v;
      notifyListeners();
    });
    _audioService.queueStream.listen((q) {
      _queue = q;
      notifyListeners();
    });
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) =>
      _audioService.playSong(song, queue: queue, index: index);
  Future<void> pause() => _audioService.pause();
  Future<void> resume() => _audioService.resume();
  Future<void> stop() => _audioService.stop();
  Future<void> next() => _audioService.next();
  Future<void> previous() => _audioService.previous();
  Future<void> seek(Duration pos) => _audioService.seek(pos);
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
