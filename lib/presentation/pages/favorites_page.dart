import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_provider.dart';
import '../components/player_bar.dart';
import '../../domain/entities/song.dart';
import '../../core/utils/duration_utils.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<FavoritesProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final auth = context.watch<AuthProvider>();
    final audio = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text(
          'Favoritos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (favorites.favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${favorites.favorites.length} canciones',
                  style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
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
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A2D42),
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
          const Text(
            'Sin canciones favoritas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega canciones desde la biblioteca\npresionando el ícono ♥',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8899AA), fontSize: 13),
          ),
        ],
      ),
    );
  }
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
    final favorites = context.watch<FavoritesProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1A2D42),
        ),
        child: Icon(
          isPlaying ? Icons.equalizer_rounded : Icons.music_note_rounded,
          color: isPlaying ? const Color(0xFFFF4D8B) : const Color(0xFF8899AA),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? const Color(0xFFFF4D8B) : Colors.white,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${song.artist} · ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF8899AA), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(song.duration),
            style: const TextStyle(color: Color(0xFF8899AA), fontSize: 12),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFFFF4D8B)),
            onPressed: () =>
                favorites.toggleFavorite(userId, song),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
