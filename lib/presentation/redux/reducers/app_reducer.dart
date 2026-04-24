import '../app_state.dart';
import '../actions/app_actions.dart';

// ─── Player Reducer ───────────────────────────────────────────────────────────
PlayerState playerReducer(PlayerState state, dynamic action) {
  if (action is PlaySongAction) {
    return state.copyWith(
      currentSong: action.song,
      queue: action.queue ?? state.queue,
      currentIndex: action.startIndex,
      isPlaying: true,
    );
  }
  if (action is PauseAction) return state.copyWith(isPlaying: false);
  if (action is ResumeAction) return state.copyWith(isPlaying: true);
  if (action is StopAction) {
    return state.copyWith(isPlaying: false, position: Duration.zero);
  }
  if (action is UpdatePositionAction) {
    return state.copyWith(position: action.position);
  }
  if (action is SetPlayingAction) {
    return state.copyWith(isPlaying: action.isPlaying);
  }
  if (action is SetVolumeAction) {
    return state.copyWith(volume: action.volume);
  }
  if (action is SetRepeatModeAction) {
    return state.copyWith(repeatMode: action.mode);
  }
  if (action is ToggleShuffleAction) {
    return state.copyWith(shuffleEnabled: !state.shuffleEnabled);
  }
  return state;
}

// ─── Library Reducer ──────────────────────────────────────────────────────────
LibraryState libraryReducer(LibraryState state, dynamic action) {
  if (action is LoadLibraryAction) {
    return state.copyWith(isLoading: true, error: null);
  }
  if (action is LibraryLoadedAction) {
    return state.copyWith(songs: action.songs, isLoading: false);
  }
  if (action is LibraryErrorAction) {
    return state.copyWith(isLoading: false, error: action.error);
  }
  if (action is SearchLibraryAction) {
    return state.copyWith(searchQuery: action.query);
  }
  if (action is PlaylistCreatedAction) {
    return state.copyWith(
      playlists: [...state.playlists, action.playlist],
    );
  }
  if (action is DeletePlaylistAction) {
    return state.copyWith(
      playlists:
          state.playlists.where((p) => p.id != action.playlistId).toList(),
    );
  }
  return state;
}

// ─── Server Reducer ───────────────────────────────────────────────────────────
ServerState serverReducer(ServerState state, dynamic action) {
  if (action is StartServerAction) {
    return state.copyWith(isStarting: true, error: null);
  }
  if (action is ServerStartedAction) {
    return state.copyWith(session: action.session, isStarting: false);
  }
  if (action is StopServerAction) {
    return state.copyWith(isStarting: false);
  }
  if (action is ServerStoppedAction) {
    return ServerState();
  }
  if (action is ServerErrorAction) {
    return state.copyWith(isStarting: false, error: action.error);
  }
  if (action is ClientConnectedAction) {
    final clients = [
      ...?state.session?.connectedClients,
      action.clientId,
    ];
    return state.copyWith(
      session: state.session?.copyWith(connectedClients: clients),
    );
  }
  if (action is ClientDisconnectedAction) {
    final clients = state.session?.connectedClients
            .where((id) => id != action.clientId)
            .toList() ??
        [];
    return state.copyWith(
      session: state.session?.copyWith(connectedClients: clients),
    );
  }
  return state;
}

// ─── Root Reducer ─────────────────────────────────────────────────────────────
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    player: playerReducer(state.player, action),
    library: libraryReducer(state.library, action),
    server: serverReducer(state.server, action),
  );
}
