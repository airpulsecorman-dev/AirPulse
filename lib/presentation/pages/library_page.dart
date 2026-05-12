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
import '../widgets/share_options_dialog.dart';
import 'artist_detail_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'intellectual_property_page.dart';

Color _randomPastel() {
  final rng = Random();
  final hue = rng.nextDouble() * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.5, 0.80).toColor();
}

class LibraryPage extends HookWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final library = useLibrary(context);
    final audio = useAudio(context);
    final favorites = context.watch<FavoritesProvider>();
    final auth = context.watch<AuthProvider>();
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
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
            onPressed: () => showShareOptionsDialog(context),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsPage()),
                  );
                  break;
                case 'privacy':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  );
                  break;
                case 'intellectual':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IntellectualPropertyPage(),
                    ),
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
                      Text('Política de Privacidad'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'intellectual',
                  child: Row(
                    children: [
                      Icon(Icons.gavel, size: 18),
                      SizedBox(width: 8),
                      Text('Propiedad Intelectual'),
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
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.red),
                      ),
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
                  onDeleteSongs: library.deleteSongs,
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
                isFavorite:
                    audio.currentSong != null &&
                    favorites.isFavorite(audio.currentSong!.id),
                onToggleFavorite: audio.currentSong == null
                    ? null
                    : () {
                        final userId = auth.currentUser?.id;
                        if (userId != null) {
                          favorites.toggleFavorite(userId, audio.currentSong!);
                        }
                      },
              ),
            )
          : null,
    );
  }
}

class _SongsList extends StatefulWidget {
  final List<Song> songs;
  final Song? currentSong;
  final ValueChanged<Song> onSongTap;
  final VoidCallback onAddSongs;
  final Future<void> Function() onRefresh;
  final Color accentColor;
  final void Function(List<String>) onDeleteSongs;

  const _SongsList({
    required this.songs,
    required this.currentSong,
    required this.onSongTap,
    required this.onAddSongs,
    required this.onRefresh,
    required this.accentColor,
    required this.onDeleteSongs,
  });

  @override
  State<_SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<_SongsList> {
  final Set<String> _selected = {};
  bool get _isSelecting => _selected.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar canciones'),
        content: Text(
          '¿Eliminar $count ${count == 1 ? 'canción' : 'canciones'} de la biblioteca?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteSongs(_selected.toList());
              setState(() => _selected.clear());
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: Container(
          color: widget.accentColor.withValues(alpha: 0.08),
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
                  onPressed: widget.onAddSongs,
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
      color: widget.accentColor.withValues(alpha: 0.08),
      child: Column(
        children: [
          if (_isSelecting)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancelar selección',
                      onPressed: () => setState(() => _selected.clear()),
                    ),
                    Text(
                      '${_selected.length} seleccionada${_selected.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (_, i) {
                  final song = songs[i];
                  final isSelected = _selected.contains(song.id);
                  return InkWell(
                    onLongPress: () => _toggleSelection(song.id),
                    onTap: _isSelecting
                        ? () => _toggleSelection(song.id)
                        : () => widget.onSongTap(song),
                    child: ColoredBox(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          if (_isSelecting)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(song.id),
                              ),
                            ),
                          Expanded(
                            child: SongTile(
                              song: song,
                              isPlaying: song.id == widget.currentSong?.id,
                              onTap: _isSelecting
                                  ? () => _toggleSelection(song.id)
                                  : () => widget.onSongTap(song),
                              onMoreTap: _isSelecting
                                  ? null
                                  : () => favs.toggleFavorite(userId, song),
                              isFavorite: favs.isFavorite(song.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
