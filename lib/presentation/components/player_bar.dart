import 'dart:math' show Random;
import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../core/utils/duration_utils.dart';
import 'song_artwork.dart';

Color _randomPastel() {
  final rng = Random();
  final hue = rng.nextDouble() * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.5, 0.80).toColor();
}

class PlayerBar extends StatelessWidget {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Stream<Duration>? positionStream;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<RepeatMode> onRepeatMode;
  final VoidCallback onShuffle;
  final ValueChanged<Color>? onAccentColorChanged;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const PlayerBar({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    required this.position,
    this.positionStream,
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.onRepeatMode,
    required this.onShuffle,
    this.onAccentColorChanged,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (positionStream != null) {
      return StreamBuilder<Duration>(
        stream: positionStream,
        initialData: position,
        builder: (context, snapshot) {
          return _PlayerBarContent(
            currentSong: currentSong,
            isPlaying: isPlaying,
            position: snapshot.data ?? position,
            repeatMode: repeatMode,
            shuffleEnabled: shuffleEnabled,
            onPlay: onPlay,
            onPause: onPause,
            onNext: onNext,
            onPrevious: onPrevious,
            onSeek: onSeek,
            onRepeatMode: onRepeatMode,
            onShuffle: onShuffle,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
          );
        },
      );
    }
    return _PlayerBarContent(
      currentSong: currentSong,
      isPlaying: isPlaying,
      position: position,
      repeatMode: repeatMode,
      shuffleEnabled: shuffleEnabled,
      onPlay: onPlay,
      onPause: onPause,
      onNext: onNext,
      onPrevious: onPrevious,
      onSeek: onSeek,
      onRepeatMode: onRepeatMode,
      onShuffle: onShuffle,
      onAccentColorChanged: onAccentColorChanged,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    );
  }
}

class _PlayerBarContent extends StatefulWidget {
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
  final ValueChanged<Color>? onAccentColorChanged;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const _PlayerBarContent({
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
    this.onAccentColorChanged,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<_PlayerBarContent> createState() => _PlayerBarContentState();
}

class _PlayerBarContentState extends State<_PlayerBarContent> {
  late Color accentColor;

  @override
  void initState() {
    super.initState();
    accentColor = _randomPastel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.currentSong?.duration ?? Duration.zero;
    final progress = playbackProgress(widget.position, total);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Artwork circular
                SongArtwork(
                  songId: widget.currentSong?.id ?? '',
                  artworkPath: widget.currentSong?.artworkPath,
                  size: 40,
                  borderRadius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentSong?.title ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.currentSong?.artist ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: progress,
              onChanged: (v) => widget.onSeek(
                Duration(milliseconds: (v * total.inMilliseconds).round()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(widget.position),
                  style: theme.textTheme.bodySmall,
                ),
                Text(formatDuration(total), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          // Song info & controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de favoritos
                IconButton(
                  tooltip: widget.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                  icon: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.isFavorite
                        ? const Color(0xFFFF4D8B)
                        : theme.colorScheme.onSurface,
                  ),
                  onPressed: widget.onToggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: widget.onPrevious,
                ),
                IconButton(
                  icon: Icon(
                    widget.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40,
                  ),
                  color: theme.colorScheme.primary,
                  onPressed: widget.isPlaying ? widget.onPause : widget.onPlay,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: widget.onNext,
                ),
                Builder(
                  builder: (context) {
                    // Determina el modo actual combinando shuffle + repeatMode
                    // 0=en orden, 1=aleatorio, 2=repetir todo, 3=repetir una
                    final int currentMode;
                    if (widget.shuffleEnabled) {
                      currentMode = 1;
                    } else if (widget.repeatMode == RepeatMode.all) {
                      currentMode = 2;
                    } else if (widget.repeatMode == RepeatMode.one) {
                      currentMode = 3;
                    } else {
                      currentMode = 0;
                    }

                    final icons = [
                      Icons.last_page_rounded,
                      Icons.shuffle,
                      Icons.repeat,
                      Icons.repeat_one,
                    ];
                    final tooltips = [
                      'En orden',
                      'Aleatorio',
                      'Repetir todo',
                      'Repetir una',
                    ];

                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: tooltips[currentMode],
                        icon: Icon(
                          icons[currentMode],
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          final next = (currentMode + 1) % 4;
                          // Desactivar shuffle si vamos a modo no-shuffle
                          if (widget.shuffleEnabled && next != 1) {
                            widget.onShuffle();
                          }
                          switch (next) {
                            case 0:
                              widget.onRepeatMode(RepeatMode.none);
                            case 1:
                              widget.onRepeatMode(RepeatMode.none);
                              widget.onShuffle();
                            case 2:
                              widget.onRepeatMode(RepeatMode.all);
                            case 3:
                              widget.onRepeatMode(RepeatMode.one);
                          }
                        },
                      ),
                    );
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
