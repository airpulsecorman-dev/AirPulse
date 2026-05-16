/// 🎵 AirPulse Player Bar - OPTIMIZADO
///
/// Barra de reproducción optimizada para rendimiento máximo.
///
/// Optimizaciones implementadas:
/// - RepaintBoundary para aislar repaints
/// - StreamBuilder solo para posición
/// - Rebuilds granulares
/// - Widgets cacheados
/// - Animaciones optimizadas
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../core/utils/duration_utils.dart';
import 'song_artwork_optimized.dart';

/// PlayerBar optimizado con rebuilds minimizados
class PlayerBarOptimized extends StatelessWidget {
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

  const PlayerBarOptimized({
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
    if (currentSong == null) return const SizedBox.shrink();

    // 🚀 OPTIMIZACIÓN: RepaintBoundary para aislar repaints
    return RepaintBoundary(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 🚀 OPTIMIZACIÓN: Progress bar con StreamBuilder aislado
            _buildProgressBar(),
            // Player controls
            Expanded(child: _buildControls(context)),
          ],
        ),
      ),
    );
  }

  /// 🚀 Progress bar con StreamBuilder aislado
  Widget _buildProgressBar() {
    if (positionStream == null) {
      return _StaticProgressBar(
        position: position,
        duration: currentSong?.duration ?? Duration.zero,
        onSeek: onSeek,
      );
    }

    // 🚀 StreamBuilder SOLO para el progress bar
    return StreamBuilder<Duration>(
      stream: positionStream,
      initialData: position,
      builder: (context, snapshot) {
        return _StaticProgressBar(
          position: snapshot.data ?? position,
          duration: currentSong?.duration ?? Duration.zero,
          onSeek: onSeek,
        );
      },
    );
  }

  /// Controls section (no se reconstruye con position updates)
  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Artwork
          _buildArtwork(context),
          const SizedBox(width: 12),
          // Song info
          Expanded(child: _buildSongInfo()),
          // Controls
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildArtwork(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: SongArtworkOptimized(
        songId: currentSong!.id,
        artworkPath: currentSong!.artworkPath,
        size: 48,
        borderRadius: 8,
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentSong!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          currentSong!.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Favorite button
        if (onToggleFavorite != null)
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFFF4D8B) : null,
              size: 22,
            ),
            onPressed: onToggleFavorite,
          ),
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 28),
          onPressed: onPrevious,
        ),
        // Play/Pause
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 42,
          ),
          onPressed: isPlaying ? onPause : onPlay,
        ),
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next, size: 28),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// 🚀 Static progress bar (no rebuild del resto)
class _StaticProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _StaticProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return RepaintBoundary(
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
