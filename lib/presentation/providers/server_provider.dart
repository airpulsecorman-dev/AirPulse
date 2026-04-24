import 'package:flutter/foundation.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/song.dart';
import '../../services/local_server_service.dart';
import '../../services/qr_service.dart';

class ServerProvider extends ChangeNotifier {
  final LocalServerService _serverService;
  // ignore: unused_field
  final QRService _qrService;

  ServerSession? _session;
  bool _isStarting = false;
  String? _error;
  List<String> _connectedClients = [];

  ServerProvider(this._serverService, this._qrService) {
    _listenToClients();
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

  Future<void> startServer({int port = 8765, List<Song> songs = const []}) async {
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

  Future<void> stopServer() async {
    await _serverService.stop();
    _session = null;
    _connectedClients = [];
    notifyListeners();
  }

  void broadcastPlayerState(Map<String, dynamic> state) {
    _serverService.broadcastPlayerState(state);
  }
}
