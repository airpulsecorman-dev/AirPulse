import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../../domain/entities/song.dart';

class AudioLocalSource {
  final AudioPlayer _player = AudioPlayer();

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> playSong(Song song) async {
    await _player.setFilePath(song.filePath);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    final sources = songs
        .map((s) => AudioSource.uri(Uri.file(s.filePath)))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
    );
  }

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  void dispose() => _player.dispose();
}
