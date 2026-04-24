import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../hooks/use_audio.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/repositories/player_repository.dart';
import '../../core/utils/duration_utils.dart';

class PlayerPage extends HookWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = useAudio(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ahora suena'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: audio.currentSong == null
          ? const Center(child: Text('No hay canción en reproducción'))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Album art placeholder
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 24,
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.music_note, size: 100),
                      ),
                      const SizedBox(height: 32),
                      // Song info
                      Text(
                        audio.currentSong!.title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        audio.currentSong!.artist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botón de favorito
                      Builder(builder: (context) {
                        final favs = context.watch<FavoritesProvider>();
                        final userId =
                            context.read<AuthProvider>().currentUser?.id ?? '';
                        final isFav =
                            favs.isFavorite(audio.currentSong!.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: const Color(0xFFFF4D8B),
                            size: 28,
                          ),
                          onPressed: () =>
                              favs.toggleFavorite(userId, audio.currentSong!),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Seek bar
                      Slider(
                        value: playbackProgress(
                          audio.position,
                          audio.currentSong!.duration,
                        ),
                        onChanged: (v) => audio.seek(
                          Duration(
                            milliseconds: (v *
                                    audio.currentSong!.duration.inMilliseconds)
                                .round(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatDuration(audio.position)),
                            Text(formatDuration(audio.currentSong!.duration)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: audio.shuffleEnabled
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            onPressed: audio.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 36),
                            onPressed: audio.previous,
                          ),
                          FilledButton(
                            onPressed: audio.isPlaying ? audio.pause : audio.resume,
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Icon(
                              audio.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 36),
                            onPressed: audio.next,
                          ),
                          IconButton(
                            icon: Icon(
                              audio.repeatMode == RepeatMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color: audio.repeatMode != RepeatMode.none
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            onPressed: () {
                              final next = switch (audio.repeatMode) {
                                RepeatMode.none => RepeatMode.all,
                                RepeatMode.all => RepeatMode.one,
                                RepeatMode.one => RepeatMode.none,
                              };
                              audio.setRepeatMode(next);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Volume
                      Row(
                        children: [
                          const Icon(Icons.volume_down),
                          Expanded(
                            child: Slider(
                              value: audio.volume,
                              onChanged: audio.setVolume,
                            ),
                          ),
                          const Icon(Icons.volume_up),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
