import 'package:flutter/foundation.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/song.dart';
import '../../services/local_server_service.dart';

class ServerController extends ChangeNotifier {
  final LocalServerService _serverService;

  ServerController(this._serverService) {
    _listenToClients();
  }

  ServerSession? _session;
  bool _isStarting = false;
  String? _error;
  List<String> _clients = [];

  ServerSession? get session => _session;
  bool get isRunning => _session?.status == ServerStatus.running;
  bool get isStarting => _isStarting;
  String? get error => _error;
  List<String> get clients => _clients;
  String? get qrPayload => _session?.qrPayload;

  void _listenToClients() {
    _serverService.connectedClientsStream.listen((c) {
      _clients = c;
      notifyListeners();
    });
    _serverService.clientCommandStream.listen(_handleClientCommand);
  }

  Future<void> start({int port = 8765, List<Song> songs = const []}) async {
    _isStarting = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _serverService.start(port: port, songs: songs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _serverService.stop();
    _session = null;
    _clients = [];
    notifyListeners();
  }

  void broadcastState(Map<String, dynamic> state) {
    _serverService.broadcastPlayerState(state);
  }

  void _handleClientCommand(Map<String, dynamic> command) {
    // Delegar al PlayerController desde el árbol de widgets usando callbacks
    debugPrint('[ServerController] Client command: $command');
  }
}
