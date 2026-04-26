import 'package:just_audio/just_audio.dart';
import '../../../domain/entities/song.dart';
import '../../../services/audio_handler.dart';

/// Fuente de audio local que delega toda la reproducción al
/// [AirPulseAudioHandler], el cual expone controles al SO (pantalla de
/// bloqueo, notificación, Bluetooth/auriculares).
class AudioLocalSource {
  final AirPulseAudioHandler _handler;

  AudioLocalSource(this._handler);

  Stream<bool> get isPlayingStream => _handler.isPlayingStream;
  Stream<Duration> get positionStream => _handler.positionStream;
  Stream<double> get volumeStream => _handler.volumeStream;
  Stream<PlayerState> get playerStateStream => _handler.playerStateStream;
  Stream<int?> get currentIndexStream => _handler.currentIndexStream;

  Future<void> playSong(Song song) => _handler.playSongDirect(song);
  Future<void> pause() => _handler.pausePlayer();
  Future<void> resume() => _handler.resumePlayer();
  Future<void> stop() => _handler.stopPlayer();
  Future<void> seek(Duration position) => _handler.seekTo(position);
  Future<void> setVolume(double volume) => _handler.setVolume(volume);
  Future<void> next() => _handler.nextTrack();
  Future<void> previous() => _handler.previousTrack();

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) =>
      _handler.setQueueFromSongs(songs, startIndex: startIndex);

  Future<void> setLoopMode(LoopMode mode) => _handler.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _handler.setShuffleModeEnabled(enabled);

  void dispose() => _handler.disposePlayer();
}
