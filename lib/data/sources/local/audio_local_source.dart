import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../../domain/entities/song.dart';

class AudioLocalSource {
  final AudioPlayer _player = AudioPlayer();
  bool _sessionConfigured = false;

  AudioLocalSource() {
    _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Solicitar foco de audio al sistema Android/iOS
    await session.setActive(true);
  }

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Future<void> playSong(Song song) async {
    await _configureAudioSession();
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
    await _configureAudioSession();
    final sources = songs
        .map((s) => AudioSource.uri(Uri.file(s.filePath)))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
      preload: true,
    );
    // Iniciar reproducción inmediatamente tras cargar la cola
    await _player.play();
  }

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  void dispose() => _player.dispose();
}
