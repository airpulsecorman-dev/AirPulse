import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../hooks/use_library.dart';
import '../hooks/use_audio.dart';
import '../components/song_tile.dart';
import '../components/player_bar.dart';
import '../../domain/entities/song.dart';

class LibraryPage extends HookWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final library = useLibrary(context);
    final audio = useAudio(context);
    final tabController = useTabController(initialLength: 3);
    final searchController = useTextEditingController();

    useEffect(() {
      library.loadLibrary();
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            icon: const Icon(Icons.wifi_tethering),
            tooltip: 'Servidor local',
            onPressed: () => Navigator.pushNamed(context, '/server'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
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
                      onSongTap: (song) => audio.play(
                        song,
                        q: library.songs,
                        index: library.songs.indexOf(song),
                      ),
                    ),
                    _AlbumsList(albums: library.albums),
                    _ArtistsList(artists: library.artists),
                  ],
                ),
      bottomNavigationBar: audio.currentSong != null
          ? PlayerBar(
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
            )
          : null,
    );
  }
}

class _SongsList extends StatelessWidget {
  final List<Song> songs;
  final Song? currentSong;
  final ValueChanged<Song> onSongTap;
  const _SongsList({
    required this.songs,
    required this.currentSong,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(child: Text('No hay canciones en la biblioteca'));
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, i) => SongTile(
        song: songs[i],
        isPlaying: songs[i].id == currentSong?.id,
        onTap: () => onSongTap(songs[i]),
      ),
    );
  }
}

class _AlbumsList extends StatelessWidget {
  final albums;
  const _AlbumsList({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(child: Text('No hay álbumes'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.album, size: 48),
              const SizedBox(height: 8),
              Text(albums[i].title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(albums[i].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistsList extends StatelessWidget {
  final artists;
  const _ArtistsList({required this.artists});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(child: Text('No hay artistas'));
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (_, i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(artists[i].name),
        subtitle: Text('${artists[i].songs.length} canciones'),
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
