import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/album.dart';
import '../components/song_tile.dart';
import '../components/player_bar.dart';
import '../hooks/use_audio.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AlbumDetailPage extends HookWidget {
  final Album album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final audio = useAudio(context);
    final favs = context.watch<FavoritesProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    final artId = album.songs.isNotEmpty
        ? (int.tryParse(album.songs.first.id) ?? 0)
        : (int.tryParse(album.id) ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              album.artist,
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
              artworkBorder: BorderRadius.zero,
              artworkHeight: 200,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.album,
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
                    '${album.songs.length} canciones',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (album.year > 0)
                  Text(
                    '${album.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: album.songs.isEmpty
                ? const Center(child: Text('No hay canciones en este álbum'))
                : ListView.builder(
                    itemCount: album.songs.length,
                    itemBuilder: (_, i) {
                      final song = album.songs[i];
                      return SongTile(
                        song: song,
                        isPlaying: song.id == audio.currentSong?.id,
                        onTap: () async {
                          await audio.play(song, q: album.songs, index: i);
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
