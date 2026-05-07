import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/song.dart';
import '../../services/audio_service.dart';
import '../../services/local_server_service.dart';
import '../../services/qr_service.dart';
import '../../services/qr_session_service.dart';

class ServerProvider extends ChangeNotifier {
  final LocalServerService _serverService;
  final AudioService _audioService;
  // ignore: unused_field
  final QRService _qrService;

  ServerSession? _session;
  bool _isStarting = false;
  String? _error;
  List<String> _connectedClients = [];

  StreamSubscription? _playingSub;
  StreamSubscription? _songSub;
  StreamSubscription? _positionSub;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  ServerProvider(this._serverService, this._audioService, this._qrService) {
    _listenToClients();
    _listenToAudio();
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
    _error = null;
    notifyListeners();
    try {
      _session = await _serverService.start(port: port, songs: songs);
      if (userId != null && _session?.serverUrl != null) {
        await QrSessionService().publishServerSession(
          userId: userId,
          serverUrl: _session!.serverUrl,
          sessionId: _session!.sessionId,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
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
