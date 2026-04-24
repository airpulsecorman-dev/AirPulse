import '../../../domain/entities/song.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/server_session.dart';
import '../../../domain/repositories/player_repository.dart';

// ─── Player Actions ───────────────────────────────────────────────────────────
class PlaySongAction {
  final Song song;
  final List<Song>? queue;
  final int startIndex;
  PlaySongAction(this.song, {this.queue, this.startIndex = 0});
}

class PauseAction {}
class ResumeAction {}
class StopAction {}
class NextTrackAction {}
class PreviousTrackAction {}

class SeekAction {
  final Duration position;
  SeekAction(this.position);
}

class SetVolumeAction {
  final double volume;
  SetVolumeAction(this.volume);
}

class SetRepeatModeAction {
  final RepeatMode mode;
  SetRepeatModeAction(this.mode);
}

class ToggleShuffleAction {}

class UpdatePositionAction {
  final Duration position;
  UpdatePositionAction(this.position);
}

class SetPlayingAction {
  final bool isPlaying;
  SetPlayingAction(this.isPlaying);
}

// ─── Library Actions ──────────────────────────────────────────────────────────
class LoadLibraryAction {}

class LibraryLoadedAction {
  final List<Song> songs;
  LibraryLoadedAction(this.songs);
}

class LibraryErrorAction {
  final String error;
  LibraryErrorAction(this.error);
}

class SearchLibraryAction {
  final String query;
  SearchLibraryAction(this.query);
}

class CreatePlaylistAction {
  final String name;
  CreatePlaylistAction(this.name);
}

class PlaylistCreatedAction {
  final Playlist playlist;
  PlaylistCreatedAction(this.playlist);
}

class AddSongToPlaylistAction {
  final String playlistId;
  final Song song;
  AddSongToPlaylistAction(this.playlistId, this.song);
}

class DeletePlaylistAction {
  final String playlistId;
  DeletePlaylistAction(this.playlistId);
}

// ─── Server Actions ───────────────────────────────────────────────────────────
class StartServerAction {
  final int port;
  StartServerAction({this.port = 8765});
}

class ServerStartedAction {
  final ServerSession session;
  ServerStartedAction(this.session);
}

class StopServerAction {}

class ServerStoppedAction {}

class ServerErrorAction {
  final String error;
  ServerErrorAction(this.error);
}

class ClientConnectedAction {
  final String clientId;
  ClientConnectedAction(this.clientId);
}

class ClientDisconnectedAction {
  final String clientId;
  ClientDisconnectedAction(this.clientId);
}
