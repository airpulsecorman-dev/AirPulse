import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/song.dart';
import '../../services/audio_service.dart';
import '../../services/local_server_service.dart';
import '../../services/ngrok_service.dart';
import '../../services/qr_service.dart';
import '../../services/qr_session_service.dart';

class ServerProvider extends ChangeNotifier {
  final LocalServerService _serverService;
  final AudioService _audioService;
  // ignore: unused_field
  final QRService _qrService;
  final NgrokService _ngrok = NgrokService();

  ServerSession? _session;
  bool _isStarting = false;
  String? _error;
  List<String> _connectedClients = [];

  StreamSubscription? _playingSub;
  StreamSubscription? _songSub;
  StreamSubscription? _positionSub;
  // ignore: unused_field
  StreamSubscription? _newClientSub;
  // ignore: unused_field
  StreamSubscription? _commandSub;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  // Songs list cacheada para resolver índices de comandos del browser
  List<Song> _songs = [];

  ServerProvider(this._serverService, this._audioService, this._qrService) {
    _listenToClients();
    _listenToAudio();
    _listenToNewClients();
    _listenToCommands();
  }

  /// Procesa comandos enviados por el browser (play, pause, resume, next, prev, seek)
  void _listenToCommands() {
    _commandSub = _serverService.clientCommandStream.listen((cmd) async {
      final type = cmd['type'] as String? ?? '';
      switch (type) {
        case 'play':
          final songId = cmd['songId'] as String?;
          final index = cmd['index'] as int?;
          if (songId != null) {
            // busca la canción por id en el cache
            final song = _songs.where((s) => s.id == songId).firstOrNull;
            if (song != null) {
              await _audioService.playSong(song, queue: _songs, index: index ?? _songs.indexOf(song));
            }
          }
          break;
        case 'pause':
          await _audioService.pause();
          break;
        case 'resume':
          await _audioService.resume();
          break;
        case 'next':
          await _audioService.next();
          break;
        case 'prev':
        case 'previous':
          await _audioService.previous();
          break;
        case 'seek':
          final ms = cmd['positionMs'];
          if (ms is num) await _audioService.seek(Duration(milliseconds: ms.toInt()));
          break;
      }
    });
  }

  /// Cuando se conecta un nuevo cliente WS, le enviamos el estado actual
  /// inmediatamente para que sincronice sin esperar el próximo cambio.
  void _listenToNewClients() {
    _newClientSub = _serverService.newClientStream.listen((clientId) {
      if (!isRunning) return;
      final state = _audioService.toJsonState(
        isPlaying: _isPlaying,
        positionMs: _position.inMilliseconds,
      );
      _serverService.sendStateToClient(clientId, state);
    });
  }

  void _listenToAudio() {
    _playingSub = _audioService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      _autoBroadcast();
    });
    _songSub = _audioService.currentSongStream.listen((_) {
      _autoBroadcast();
    });
    _positionSub = _audioService.positionStream.listen((pos) {
      _position = pos;
      // Broadcast posición cada ~2 s para no saturar
      if (pos.inMilliseconds % 2000 < 200) _autoBroadcast();
    });
  }

  void _autoBroadcast() {
    if (!isRunning) return;
    final state = _audioService.toJsonState(
      isPlaying: _isPlaying,
      positionMs: _position.inMilliseconds,
    );
    _serverService.broadcastPlayerState(state);
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _songSub?.cancel();
    _positionSub?.cancel();
    _newClientSub?.cancel();
    _commandSub?.cancel();
    super.dispose();
  }

  ServerSession? get session => _session;
  bool get isStarting => _isStarting;
  bool get isRunning => _session?.status == ServerStatus.running;
  String? get error => _error;
  List<String> get connectedClients => _connectedClients;
  String? get serverUrl => _session?.serverUrl;
  String? get qrPayload => _session?.qrPayload;

  void _listenToClients() {
    _serverService.connectedClientsStream.listen((clients) {
      _connectedClients = clients;
      notifyListeners();
    });
  }

  String? _activeUserId;

  Future<void> startServer({
    int port = 8765,
    List<Song> songs = const [],
    String? userId,
  }) async {
    _isStarting = true;
    _activeUserId = userId;
    _songs = songs;
    _error = null;
    notifyListeners();
    try {
      _session = await _serverService.start(
        port: port,
        songs: songs,
        onPlayerStateRequested: (map) {
          final state = _audioService.toJsonState(
            isPlaying: _isPlaying,
            positionMs: _position.inMilliseconds,
          );
          map.addAll(state);
        },
      );

      // Intentar abrir túnel ngrok HTTPS para evitar Mixed Content desde HTTPS
      final ngrokUrl = await _ngrok.startTunnel(port);
      final publicUrl = ngrokUrl ?? _session?.serverUrl;

      if (userId != null && publicUrl != null) {
        await QrSessionService().publishServerSession(
          userId: userId,
          serverUrl: publicUrl,
          sessionId: _session!.sessionId,
        );
      }

      // Actualizar la sesión con la URL pública (ngrok o local)
      if (_session != null && publicUrl != null && publicUrl != _session!.serverUrl) {
        _session = _session!.copyWith(publicUrl: publicUrl);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    await _ngrok.stopTunnel();
    if (_activeUserId != null) {
      await QrSessionService().clearServerSession(_activeUserId!);
      _activeUserId = null;
    }
    await _serverService.stop();
    _session = null;
    _connectedClients = [];
    notifyListeners();
  }

  void broadcastPlayerState(Map<String, dynamic> state) {
    _serverService.broadcastPlayerState(state);
  }

  void broadcastCurrentState() => _autoBroadcast();
}
