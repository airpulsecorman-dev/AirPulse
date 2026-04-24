import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../core/utils/duration_utils.dart';

class PlayerBar extends StatelessWidget {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<RepeatMode> onRepeatMode;
  final VoidCallback onShuffle;

  const PlayerBar({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.onRepeatMode,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = currentSong?.duration ?? Duration.zero;
    final progress = playbackProgress(position, total);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: progress,
              onChanged: (v) => onSeek(
                Duration(milliseconds: (v * total.inMilliseconds).round()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position),
                    style: theme.textTheme.bodySmall),
                Text(formatDuration(total), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          // Song info & controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong?.title ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentSong?.artist ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Shuffle
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: onShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPrevious,
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 40,
                  ),
                  color: theme.colorScheme.primary,
                  onPressed: isPlaying ? onPause : onPlay,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNext,
                ),
                // Repeat
                IconButton(
                  icon: Icon(
                    repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: repeatMode != RepeatMode.none
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    final next = switch (repeatMode) {
                      RepeatMode.none => RepeatMode.all,
                      RepeatMode.all => RepeatMode.one,
                      RepeatMode.one => RepeatMode.none,
                    };
                    onRepeatMode(next);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
