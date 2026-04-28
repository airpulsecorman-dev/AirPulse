import 'dart:io';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../hooks/use_library.dart';
import '../hooks/use_audio.dart';
import '../components/song_tile.dart';
import '../components/song_artwork.dart';
import '../components/player_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../../domain/entities/song.dart';
import 'album_detail_page.dart';
import 'artist_detail_page.dart';

Color _randomPastel() {
  final rng = Random();
  final hue = rng.nextDouble() * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.5, 0.80).toColor();
}

void _showDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(content),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class LibraryPage extends HookWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final library = useLibrary(context);
    final audio = useAudio(context);
    final theme = Theme.of(context);
    final tabController = useTabController(initialLength: 3);
    final searchController = useTextEditingController();
    final accentColor = useState<Color>(_randomPastel());

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        library.loadLibrary();
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AirPulse'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Buscar canciones…',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          library.setSearchQuery('');
                        },
                      ),
                  ],
                  onChanged: library.setSearchQuery,
                ),
              ),
              TabBar(
                controller: tabController,
                labelColor: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Canciones'),
                  Tab(text: 'Álbumes'),
                  Tab(text: 'Artistas'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFFFF4D8B)),
            tooltip: 'Favoritos',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            tooltip: 'Servidor local',
            onPressed: () => Navigator.pushNamed(context, '/server'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'terms':
                  _showDialog(
                    context,
                    'Términos y Condiciones',
                    'Aquí van los términos y condiciones de AirPulse.',
                  );
                  break;
                case 'privacy':
                  _showDialog(
                    context,
                    'Política de Privacidad',
                    'Aquí va la política de privacidad de AirPulse.',
                  );
                  break;
                case 'logout':
                  context.read<AuthProvider>().logout();
                  break;
              }
            },
            itemBuilder: (_) {
              final user = context.read<AuthProvider>().currentUser;
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 8),
                      Text('Mi Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 18),
                      SizedBox(width: 8),
                      Text('Ajustes'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'terms',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 18),
                      SizedBox(width: 8),
                      Text('Términos y Condiciones'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip, size: 18),
                      SizedBox(width: 8),
                      Text('Privacidad y Servicios'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: library.isLoading
          ? const Center(child: CircularProgressIndicator())
          : library.error != null
          ? _ErrorView(error: library.error!, onRetry: library.loadLibrary)
          : TabBarView(
              controller: tabController,
              children: [
                _SongsList(
                  songs: library.songs,
                  currentSong: audio.currentSong,
                  onAddSongs: library.addSongsFromFiles,
                  onRefresh: library.loadLibrary,
                  accentColor: accentColor.value,
                  onSongTap: (song) async {
                    await audio.play(
                      song,
                      q: library.songs,
                      index: library.songs.indexOf(song),
                    );
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/player');
                    }
                  },
                ),
                _AlbumsList(
                  albums: library.albums,
                  onRefresh: library.loadLibrary,
                  accentColor: accentColor.value,
                ),
                _ArtistsList(
                  artists: library.artists,
                  onRefresh: library.loadLibrary,
                  accentColor: accentColor.value,
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
                onAccentColorChanged: (newColor) {
                  accentColor.value = newColor;
                },
              ),
            )
          : null,
    );
  }
}

class _SongsList extends StatelessWidget {
  final List<Song> songs;
  final Song? currentSong;
  final ValueChanged<Song> onSongTap;
  final VoidCallback onAddSongs;
  final Future<void> Function() onRefresh;
  final Color accentColor;

  const _SongsList({
    required this.songs,
    required this.currentSong,
    required this.onSongTap,
    required this.onAddSongs,
    required this.onRefresh,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Container(
          color: accentColor.withValues(alpha: 0.08),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.library_music_outlined,
                  size: 72,
                  color: Color(0xFF8899AA),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay canciones en la biblioteca',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8899AA)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agrega archivos de audio desde tu dispositivo',
                  style: TextStyle(fontSize: 13, color: Color(0xFF566D80)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAddSongs,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar canciones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D8B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final favs = context.watch<FavoritesProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    return Container(
      color: accentColor.withValues(alpha: 0.08),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) => SongTile(
            song: songs[i],
            isPlaying: songs[i].id == currentSong?.id,
            onTap: () => onSongTap(songs[i]),
            onMoreTap: () => favs.toggleFavorite(userId, songs[i]),
            isFavorite: favs.isFavorite(songs[i].id),
          ),
        ),
      ),
    );
  }
}

class _AlbumsList extends StatelessWidget {
  final albums;
  final Future<void> Function() onRefresh;
  final Color accentColor;

  const _AlbumsList({
    required this.albums,
    required this.onRefresh,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Container(
          color: accentColor.withValues(alpha: 0.08),
          child: const Center(child: Text('No hay álbumes')),
        ),
      );
    }
    return Container(
      color: accentColor.withValues(alpha: 0.08),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final album = albums[i];
            final firstSong = album.songs.isNotEmpty ? album.songs.first : null;
            final artId = firstSong != null
                ? (int.tryParse(firstSong.id) ?? 0)
                : (int.tryParse(album.id) ?? 0);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailPage(album: album),
                ),
              ),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Platform.isMacOS
                            ? SongArtwork(
                                songId: firstSong?.id ?? album.id,
                                artworkPath:
                                    firstSong?.artworkPath ?? album.artworkPath,
                                size: double.infinity,
                                borderRadius: 0,
                                nullWidget: Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.album,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              )
                            : QueryArtworkWidget(
                                id: artId,
                                type: ArtworkType.AUDIO,
                                artworkFit: BoxFit.cover,
                                artworkWidth: double.infinity,
                                artworkBorder: BorderRadius.zero,
                                keepOldArtwork: true,
                                nullArtworkWidget: Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.album,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          Text(
                            album.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            album.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArtistsList extends StatelessWidget {
  final artists;
  final Future<void> Function() onRefresh;
  final Color accentColor;

  const _ArtistsList({
    required this.artists,
    required this.onRefresh,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: Container(
          color: accentColor.withValues(alpha: 0.08),
          child: const Center(child: Text('No hay artistas')),
        ),
      );
    }
    return Container(
      color: accentColor.withValues(alpha: 0.08),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          itemCount: artists.length,
          itemBuilder: (_, i) {
            final artist = artists[i];
            final firstSong = artist.songs.isNotEmpty
                ? artist.songs.first
                : null;
            final artId = firstSong != null
                ? (int.tryParse(firstSong.id) ?? 0)
                : (int.tryParse(artist.id) ?? 0);
            return ListTile(
              leading: Platform.isMacOS
                  ? SongArtwork(
                      songId: firstSong?.id ?? artist.id,
                      artworkPath: firstSong?.artworkPath ?? artist.artworkPath,
                      size: 48,
                      borderRadius: 24,
                      nullWidget: const CircleAvatar(child: Icon(Icons.person)),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: QueryArtworkWidget(
                        id: artId,
                        type: ArtworkType.AUDIO,
                        artworkWidth: 48,
                        artworkHeight: 48,
                        artworkFit: BoxFit.cover,
                        artworkBorder: BorderRadius.circular(24),
                        keepOldArtwork: true,
                        nullArtworkWidget: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                      ),
                    ),
              title: Text(artist.name),
              subtitle: Text('${artist.songs.length} canciones'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailPage(artist: artist),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
