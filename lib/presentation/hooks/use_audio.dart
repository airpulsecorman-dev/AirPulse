import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';

/// Hook para acceder y controlar la reproducción de audio.
AudioHookResult useAudio(BuildContext context) {
  final provider = useListenable(context.read<AudioProvider>());
  final currentSong = provider.currentSong;
  final isPlaying = provider.isPlaying;
  final position = provider.position;
  final volume = provider.volume;
  final queue = provider.queue;
  final repeatMode = provider.repeatMode;
  final shuffleEnabled = provider.shuffleEnabled;

  return AudioHookResult(
    currentSong: currentSong,
    isPlaying: isPlaying,
    position: position,
    positionStream: provider.positionStream,
    volume: volume,
    queue: queue,
    repeatMode: repeatMode,
    shuffleEnabled: shuffleEnabled,
    play: (song, {q, index}) => provider.play(song, queue: q, index: index),
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

class AudioHookResult {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Stream<Duration> positionStream;
  final double volume;
  final List<Song> queue;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final Future<void> Function(Song, {List<Song>? q, int? index}) play;
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
