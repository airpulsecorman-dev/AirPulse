import 'package:redux/redux.dart';
import 'package:airpulse/services/audio_service.dart' as svc;
import 'package:airpulse/services/library_service.dart';
import 'package:airpulse/services/local_server_service.dart';
import 'package:airpulse/core/di/service_locator.dart';
import '../app_state.dart';
import '../actions/app_actions.dart';

// ─── Player Middleware ────────────────────────────────────────────────────────
void playerMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  final audio = _audioSvc;

  if (action is PlaySongAction) {
    audio.playSong(action.song, queue: action.queue, index: action.startIndex);
  } else if (action is PauseAction) {
    audio.pause();
  } else if (action is ResumeAction) {
    audio.resume();
  } else if (action is StopAction) {
    audio.stop();
  } else if (action is NextTrackAction) {
    audio.next();
  } else if (action is PreviousTrackAction) {
    audio.previous();
  } else if (action is SeekAction) {
    audio.seek(action.position);
  } else if (action is SetVolumeAction) {
    audio.setVolume(action.volume);
  } else if (action is SetRepeatModeAction) {
    audio.setRepeatMode(action.mode);
  } else if (action is ToggleShuffleAction) {
    audio.toggleShuffle();
  }

  next(action);
}

// ─── Library Middleware ───────────────────────────────────────────────────────
void libraryMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  if (action is LoadLibraryAction) {
    next(action);
    _librarySvc
        .getAllSongs()
        .then((songs) {
          store.dispatch(LibraryLoadedAction(songs));
        })
        .catchError((e) {
          store.dispatch(LibraryErrorAction(e.toString()));
        });
    return;
  }
  if (action is CreatePlaylistAction) {
    _librarySvc.createPlaylist(action.name).then((playlist) {
      store.dispatch(PlaylistCreatedAction(playlist));
    });
  }
  if (action is AddSongToPlaylistAction) {
    _librarySvc.addSongToPlaylist(action.playlistId, action.song);
  }
  if (action is DeletePlaylistAction) {
    _librarySvc.deletePlaylist(action.playlistId);
  }
  next(action);
}

// ─── Server Middleware ────────────────────────────────────────────────────────
void serverMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  if (action is StartServerAction) {
    next(action);
    _serverSvc
        .start(port: action.port)
        .then((session) {
          store.dispatch(ServerStartedAction(session));
        })
        .catchError((e) => store.dispatch(ServerErrorAction(e.toString())));
    return;
  }
  if (action is StopServerAction) {
    _serverSvc.stop().then((_) => store.dispatch(ServerStoppedAction()));
  }
  next(action);
}

// ─── Lazy service getters via DI ─────────────────────────────────────────────
svc.AudioService get _audioSvc => sl<svc.AudioService>();
LibraryService get _librarySvc => sl<LibraryService>();
LocalServerService get _serverSvc => sl<LocalServerService>();

// ─── Combined middleware list ─────────────────────────────────────────────────
List<Middleware<AppState>> get appMiddleware => [
  TypedMiddleware<AppState, dynamic>(playerMiddleware).call,
  TypedMiddleware<AppState, dynamic>(libraryMiddleware).call,
  TypedMiddleware<AppState, dynamic>(serverMiddleware).call,
];
