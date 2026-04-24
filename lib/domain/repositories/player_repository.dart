import '../entities/song.dart';

enum RepeatMode { none, one, all }

abstract class PlayerRepository {
  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> next();
  Future<void> previous();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setQueue(List<Song> songs, {int startIndex = 0});
  Future<void> setRepeatMode(RepeatMode mode);
  Future<void> toggleShuffle();
  Stream<Song?> get currentSongStream;
  Stream<Duration> get positionStream;
  Stream<bool> get isPlayingStream;
  Stream<double> get volumeStream;
}
