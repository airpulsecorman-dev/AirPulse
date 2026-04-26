import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/artist.dart';
import '../components/song_tile.dart';
import '../components/player_bar.dart';
import '../hooks/use_audio.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';

class ArtistDetailPage extends HookWidget {
  final Artist artist;

  const ArtistDetailPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final audio = useAudio(context);
    final favs = context.watch<FavoritesProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    final artId = artist.songs.isNotEmpty
        ? (int.tryParse(artist.songs.first.id) ?? 0)
        : (int.tryParse(artist.id) ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${artist.songs.length} canciones',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Artwork header
          SizedBox(
            height: 200,
            width: double.infinity,
            child: QueryArtworkWidget(
              id: artId,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              artworkWidth: double.infinity,
              artworkHeight: 200,
              artworkBorder: BorderRadius.zero,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    artist.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproducir todo'),
                  onPressed: artist.songs.isEmpty
                      ? null
                      : () async {
                          await audio.play(
                            artist.songs.first,
                            q: artist.songs,
                            index: 0,
                          );
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/player');
                          }
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: artist.songs.isEmpty
                ? const Center(child: Text('No hay canciones de este artista'))
                : ListView.builder(
                    itemCount: artist.songs.length,
                    itemBuilder: (_, i) {
                      final song = artist.songs[i];
                      return SongTile(
                        song: song,
                        isPlaying: song.id == audio.currentSong?.id,
                        onTap: () async {
                          await audio.play(song, q: artist.songs, index: i);
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/player');
                          }
                        },
                        onMoreTap: () => favs.toggleFavorite(userId, song),
                        isFavorite: favs.isFavorite(song.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: audio.currentSong != null
          ? GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/player'),
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
            )
          : null,
    );
  }
}
