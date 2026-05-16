/// 🪝 AirPulse Library Hook - OPTIMIZADO
///
/// Hook optimizado para acceder a la biblioteca musical.
///
/// Optimizaciones implementadas:
/// - Sin doble watching
/// - Selectores granulares disponibles
/// - Memory-efficient
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider_optimized.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';

/// Hook optimizado para biblioteca
///
/// USO BÁSICO:
/// ```dart
/// final library = useLibraryOptimized(context);
/// ```
///
/// USO AVANZADO (rebuilds granulares):
/// ```dart
/// final songs = context.select<LibraryProviderOptimized, List<Song>>(
///   (p) => p.songs
/// );
/// ```
LibraryHookResult useLibraryOptimized(BuildContext context) {
  // 🚀 Solo watch, sin useListenable redundante
  final provider = context.watch<LibraryProviderOptimized>();

  return LibraryHookResult(
    songs: provider.songs,
    albums: provider.albums,
    artists: provider.artists,
    playlists: provider.playlists,
    isLoading: provider.isLoading,
    error: provider.error,
    searchQuery: provider.searchQuery,
    totalSongs: provider.totalSongs,
    loadedSongs: provider.loadedSongs,
    loadLibrary: provider.loadLibrary,
    setSearchQuery: provider.setSearchQuery,
    clearSearch: provider.clearSearch,
    createPlaylist: provider.createPlaylist,
    addSongToPlaylist: provider.addSongToPlaylist,
    deletePlaylist: provider.deletePlaylist,
    addSongsFromFiles: provider.addSongsFromFiles,
    deleteSongs: provider.deleteSongs,
    loadMore: provider.loadMore,
    checkPrefetch: provider.checkPrefetch,
  );
}

/// Hook para solo leer (sin rebuilds)
LibraryHookResult useLibraryRead(BuildContext context) {
  final provider = context.read<LibraryProviderOptimized>();

  return LibraryHookResult(
    songs: provider.songs,
    albums: provider.albums,
    artists: provider.artists,
    playlists: provider.playlists,
    isLoading: provider.isLoading,
    error: provider.error,
    searchQuery: provider.searchQuery,
    totalSongs: provider.totalSongs,
    loadedSongs: provider.loadedSongs,
    loadLibrary: provider.loadLibrary,
    setSearchQuery: provider.setSearchQuery,
    clearSearch: provider.clearSearch,
    createPlaylist: provider.createPlaylist,
    addSongToPlaylist: provider.addSongToPlaylist,
    deletePlaylist: provider.deletePlaylist,
    addSongsFromFiles: provider.addSongsFromFiles,
    deleteSongs: provider.deleteSongs,
    loadMore: provider.loadMore,
    checkPrefetch: provider.checkPrefetch,
  );
}

/// Result object
class LibraryHookResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int totalSongs;
  final int loadedSongs;
  final Future<void> Function() loadLibrary;
  final void Function(String) setSearchQuery;
  final void Function() clearSearch;
  final Future<void> Function(String) createPlaylist;
  final Future<void> Function(String, Song) addSongToPlaylist;
  final Future<void> Function(String) deletePlaylist;
  final Future<void> Function() addSongsFromFiles;
  final Future<void> Function(List<String>) deleteSongs;
  final Future<void> Function() loadMore;
  final void Function(int) checkPrefetch;

  const LibraryHookResult({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.isLoading,
    required this.error,
    required this.searchQuery,
    required this.totalSongs,
    required this.loadedSongs,
    required this.loadLibrary,
    required this.setSearchQuery,
    required this.clearSearch,
    required this.createPlaylist,
    required this.addSongToPlaylist,
    required this.deletePlaylist,
    required this.addSongsFromFiles,
    required this.deleteSongs,
    required this.loadMore,
    required this.checkPrefetch,
  });
}

/// 🚀 EXTENSION: Selectores para rebuilds granulares
extension LibrarySelectorsExtension on BuildContext {
  /// Select solo songs (rebuild solo cuando cambian canciones)
  List<Song> selectSongs() {
    return select<LibraryProviderOptimized, List<Song>>((p) => p.songs);
  }

  /// Select solo isLoading
  bool selectLibraryLoading() {
    return select<LibraryProviderOptimized, bool>((p) => p.isLoading);
  }

  /// Select solo searchQuery
  String selectSearchQuery() {
    return select<LibraryProviderOptimized, String>((p) => p.searchQuery);
  }

  /// Select count de canciones
  int selectSongsCount() {
    return select<LibraryProviderOptimized, int>((p) => p.songs.length);
  }
}
