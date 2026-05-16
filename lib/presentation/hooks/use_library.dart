import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';

/// Hook para acceder a la biblioteca de música.
LibraryHookResult useLibrary(BuildContext context) {
  // Usar watch en lugar de read para que el hook se actualice cuando cambie el provider
  final provider = context.watch<LibraryProvider>();

  // Asegurar que el widget se reconstruya cuando cambien propiedades relevantes
  useListenable(provider);

  return LibraryHookResult(
    songs: provider.songs,
    albums: provider.albums,
    artists: provider.artists,
    playlists: provider.playlists,
    isLoading: provider.isLoading,
    error: provider.error,
    searchQuery: provider.searchQuery,
    loadLibrary: provider.loadLibrary,
    setSearchQuery: provider.setSearchQuery,
    createPlaylist: provider.createPlaylist,
    addSongToPlaylist: provider.addSongToPlaylist,
    deletePlaylist: provider.deletePlaylist,
    addSongsFromFiles: provider.addSongsFromFiles,
    deleteSongs: provider.deleteSongs,
  );
}

class LibraryHookResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final Future<void> Function() loadLibrary;
  final void Function(String) setSearchQuery;
  final Future<void> Function(String) createPlaylist;
  final Future<void> Function(String, Song) addSongToPlaylist;
  final Future<void> Function(String) deletePlaylist;
  final Future<void> Function() addSongsFromFiles;
  final Future<void> Function(List<String>) deleteSongs;

  const LibraryHookResult({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.isLoading,
    required this.error,
    required this.searchQuery,
    required this.loadLibrary,
    required this.setSearchQuery,
    required this.createPlaylist,
    required this.addSongToPlaylist,
    required this.deletePlaylist,
    required this.addSongsFromFiles,
    required this.deleteSongs,
  });
}
