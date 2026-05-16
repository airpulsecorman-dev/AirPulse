/// 🪝 AirPulse Audio Hook - OPTIMIZADO
///
/// Hook optimizado para acceder al audio player.
///
/// Optimizaciones implementadas:
/// - Sin doble watching (eliminado useListenable redundante)
/// - Selectores granulares disponibles
/// - Memory-efficient
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider_optimized.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';

/// Hook optimizado para audio
///
/// USO BÁSICO (rebuild en todos los cambios):
/// ```dart
/// final audio = useAudioOptimized(context);
/// ```
///
/// USO AVANZADO (rebuilds granulares con select):
/// ```dart
/// final currentSong = context.select<AudioProviderOptimized, Song?>(
///   (p) => p.currentSong
/// );
/// ```
AudioHookResult useAudioOptimized(BuildContext context) {
  // 🚀 OPTIMIZACIÓN: Solo watch, SIN useListenable (era redundante)
  final provider = context.watch<AudioProviderOptimized>();

  return AudioHookResult(
    currentSong: provider.currentSong,
    isPlaying: provider.isPlaying,
    position: provider.position,
    positionStream: provider.positionStream,
    volume: provider.volume,
    queue: provider.queue,
    repeatMode: provider.repeatMode,
    shuffleEnabled: provider.shuffleEnabled,
    play: provider.play,
    pause: provider.pause,
    resume: provider.resume,
    next: provider.next,
    previous: provider.previous,
    seek: provider.seek,
    setVolume: provider.setVolume,
    setRepeatMode: provider.setRepeatMode,
    toggleShuffle: provider.toggleShuffle,
  );
}

/// Hook para solo leer (sin rebuilds)
///
/// USO: Para acceder a métodos sin escuchar cambios
/// ```dart
/// final audioRead = useAudioRead(context);
/// audioRead.play(song);  // No causa rebuild
/// ```
AudioHookResult useAudioRead(BuildContext context) {
  final provider = context.read<AudioProviderOptimized>();

  return AudioHookResult(
    currentSong: provider.currentSong,
    isPlaying: provider.isPlaying,
    position: provider.position,
    positionStream: provider.positionStream,
    volume: provider.volume,
    queue: provider.queue,
    repeatMode: provider.repeatMode,
    shuffleEnabled: provider.shuffleEnabled,
    play: provider.play,
    pause: provider.pause,
    resume: provider.resume,
    next: provider.next,
    previous: provider.previous,
    seek: provider.seek,
    setVolume: provider.setVolume,
    setRepeatMode: provider.setRepeatMode,
    toggleShuffle: provider.toggleShuffle,
  );
}

/// Result object
class AudioHookResult {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Stream<Duration> positionStream;
  final double volume;
  final List<Song> queue;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final Future<void> Function(Song, {List<Song>? queue, int? index}) play;
  final Future<void> Function() pause;
  final Future<void> Function() resume;
  final Future<void> Function() next;
  final Future<void> Function() previous;
  final Future<void> Function(Duration) seek;
  final Future<void> Function(double) setVolume;
  final Future<void> Function(RepeatMode) setRepeatMode;
  final Future<void> Function() toggleShuffle;

  const AudioHookResult({
    required this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.positionStream,
    required this.volume,
    required this.queue,
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.play,
    required this.pause,
    required this.resume,
    required this.next,
    required this.previous,
    required this.seek,
    required this.setVolume,
    required this.setRepeatMode,
    required this.toggleShuffle,
  });
}

/// 🚀 EXTENSION: Selectores para rebuilds granulares
extension AudioSelectorsExtension on BuildContext {
  /// Select solo currentSong (rebuild solo cuando cambia la canción)
  Song? selectCurrentSong() {
    return select<AudioProviderOptimized, Song?>((p) => p.currentSong);
  }

  /// Select solo isPlaying
  bool selectIsPlaying() {
    return select<AudioProviderOptimized, bool>((p) => p.isPlaying);
  }

  /// Select combinación song + playing
  SongPlayingState selectSongPlaying() {
    return select<AudioProviderOptimized, SongPlayingState>(
      (p) => SongPlayingState(p.currentSong, p.isPlaying),
    );
  }
}

/// Estado combinado para comparación
class SongPlayingState {
  final Song? song;
  final bool isPlaying;

  const SongPlayingState(this.song, this.isPlaying);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongPlayingState &&
          song?.id == other.song?.id &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode => (song?.id ?? '').hashCode ^ isPlaying.hashCode;
}
