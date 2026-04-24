import 'package:just_audio/just_audio.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../sources/local/audio_local_source.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final AudioLocalSource _audioSource;
  Song? _currentSong;
  // ignore: unused_field
  List<Song> _queue = [];

  PlayerRepositoryImpl(this._audioSource);

  @override
  Future<void> play(Song song) async {
    _currentSong = song;
    await _audioSource.playSong(song);
  }

  @override
  Future<void> pause() => _audioSource.pause();

  @override
  Future<void> resume() => _audioSource.resume();

  @override
  Future<void> stop() => _audioSource.stop();

  @override
  Future<void> next() => _audioSource.next();

  @override
  Future<void> previous() => _audioSource.previous();

  @override
  Future<void> seek(Duration position) => _audioSource.seek(position);

  @override
  Future<void> setVolume(double volume) => _audioSource.setVolume(volume);

  @override
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = songs;
    _currentSong = songs.isNotEmpty ? songs[startIndex] : null;
    await _audioSource.setQueue(songs, startIndex: startIndex);
  }

  @override
  Future<void> setRepeatMode(RepeatMode mode) async {
    final loopMode = switch (mode) {
      RepeatMode.none => LoopMode.off,
      RepeatMode.one => LoopMode.one,
      RepeatMode.all => LoopMode.all,
    };
    await _audioSource.setLoopMode(loopMode);
  }

  @override
  Future<void> toggleShuffle() async {
    await _audioSource.setShuffleModeEnabled(true);
  }

  @override
  Stream<Song?> get currentSongStream async* {
    yield _currentSong;
  }

  @override
  Stream<Duration> get positionStream => _audioSource.positionStream;

  @override
  Stream<bool> get isPlayingStream => _audioSource.isPlayingStream;

  @override
  Stream<double> get volumeStream => _audioSource.volumeStream;
}
