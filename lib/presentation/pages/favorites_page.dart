import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_provider.dart';
import '../components/player_bar.dart';
import '../components/favorite_button.dart';
import '../../domain/entities/song.dart';
import '../../core/utils/duration_utils.dart';

class FavoritesPage extends HookWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final auth = context.watch<AuthProvider>();
    final audio = context.watch<AudioProvider>();
    final theme = Theme.of(context);

    // ScrollController para desplazar a la canción actual
    final scrollController = useScrollController();

    // Cargar favoritos al iniciar
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userId = auth.currentUser?.id;
        if (userId != null) {
          favorites.loadFavorites(userId);
        }
      });
      return null;
    }, []);

    // Desplazar automáticamente a la canción actual cuando cambia
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (audio.currentSong != null && favorites.favorites.isNotEmpty) {
          final currentIndex = favorites.favorites.indexWhere(
            (song) => song.id == audio.currentSong!.id,
          );
          if (currentIndex != -1 && scrollController.hasClients) {
            // Calcular la posición aproximada del item (altura promedio de ListTile ~72px)
            final position = currentIndex * 72.0;
            scrollController.animateTo(
              position,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
      return null;
    }, [audio.currentSong?.id]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (favorites.favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${favorites.favorites.length} canciones',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: favorites.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D8B)),
            )
          : favorites.favorites.isEmpty
          ? _buildEmptyState(context, theme)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: favorites.favorites.length,
                    itemBuilder: (context, index) {
                      final song = favorites.favorites[index];
                      final isPlaying =
                          audio.currentSong?.id == song.id && audio.isPlaying;
                      return _FavoriteTile(
                        song: song,
                        isPlaying: isPlaying,
                        userId: auth.currentUser?.id ?? '',
                        onTap: () => audio.play(
                          song,
                          queue: favorites.favorites,
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
                if (audio.currentSong != null)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/player'),
                    child: PlayerBar(
                      currentSong: audio.currentSong,
                      isPlaying: audio.isPlaying,
                      position: audio.position,
                      positionStream: audio.positionStream,
                      repeatMode: audio.repeatMode,
                      shuffleEnabled: audio.shuffleEnabled,
                      onPlay: audio.resume,
                      onPause: audio.pause,
                      onNext: audio.next,
                      onPrevious: audio.previous,
                      onSeek: audio.seek,
                      onRepeatMode: audio.setRepeatMode,
                      onShuffle: audio.toggleShuffle,
                    ),
                  ),
              ],
            ),
    );
  }
}

Widget _buildEmptyState(BuildContext context, ThemeData theme) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8B).withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_border,
            size: 40,
            color: Color(0xFFFF4D8B),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sin canciones favoritas',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Agrega canciones desde la biblioteca\npresionando el ícono ♥',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _FavoriteTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final String userId;
  final VoidCallback onTap;

  const _FavoriteTile({
    required this.song,
    required this.isPlaying,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: QueryArtworkWidget(
          id: int.tryParse(song.id) ?? 0,
          type: ArtworkType.AUDIO,
          artworkWidth: 48,
          artworkHeight: 48,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.circular(10),
          keepOldArtwork: true,
          nullArtworkWidget: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              isPlaying ? Icons.equalizer_rounded : Icons.music_note_rounded,
              color: isPlaying
                  ? const Color(0xFFFF4D8B)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying
              ? const Color(0xFFFF4D8B)
              : theme.colorScheme.onSurface,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${song.artist} · ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(song.duration),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          // Usa el nuevo componente FavoriteButton
          FavoriteButton(
            song: song,
            size: 24,
            onChanged: (isFavorite) {
              // Opcional: feedback adicional
              if (!isFavorite) {
                // La canción fue eliminada de favoritos
                // Puedes agregar lógica adicional aquí
              }
            },
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
