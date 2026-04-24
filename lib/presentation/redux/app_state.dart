import '../../domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/repositories/player_repository.dart';

// ─── Player State ────────────────────────────────────────────────────────────
class PlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final double volume;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.volume = 1.0,
    this.repeatMode = RepeatMode.none,
    this.shuffleEnabled = false,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    double? volume,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      volume: volume ?? this.volume,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    );
  }
}

// ─── Library State ────────────────────────────────────────────────────────────
class LibraryState {
  final List<Song> songs;
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const LibraryState({
    this.songs = const [],
    this.playlists = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Playlist>? playlists,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ─── Server State ─────────────────────────────────────────────────────────────
class ServerState {
  final ServerSession? session;
  final bool isStarting;
  final String? error;

  const ServerState({
    this.session,
    this.isStarting = false,
    this.error,
  });

  ServerState copyWith({
    ServerSession? session,
    bool? isStarting,
    String? error,
  }) {
    return ServerState(
      session: session ?? this.session,
      isStarting: isStarting ?? this.isStarting,
      error: error,
    );
  }
}

// ─── App State ────────────────────────────────────────────────────────────────
class AppState {
  final PlayerState player;
  final LibraryState library;
  final ServerState server;

  const AppState({
    this.player = const PlayerState(),
    this.library = const LibraryState(),
    this.server = const ServerState(),
  });

  AppState copyWith({
    PlayerState? player,
    LibraryState? library,
    ServerState? server,
  }) {
    return AppState(
      player: player ?? this.player,
      library: library ?? this.library,
      server: server ?? this.server,
    );
  }
}
