import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/entities/server_session.dart';
import '../domain/entities/song.dart';
import '../data/sources/remote/websocket_source.dart';

class LocalServerService {
  static const _uuid = Uuid();

  HttpServer? _server;
  ServerSession? _activeSession;
  final WebSocketSource _wsSource = WebSocketSource();

  Stream<Map<String, dynamic>> get clientCommandStream =>
      _wsSource.commandStream;
  Stream<List<String>> get connectedClientsStream =>
      _wsSource.connectedClientsStream;
  ServerSession? get activeSession => _activeSession;

  Future<ServerSession> start({
    int port = 8765,
    List<Song> songs = const [],
    Function(Map<String, dynamic>)? onPlayerStateRequested,
  }) async {
    if (_server != null) await stop();

    final ip = await _getLocalIp();
    final sessionId = _uuid.v4();

    final router = Router()
      ..get('/', (Request req) => _handleRoot(req, ip, port, sessionId))
      ..get('/health', _handleHealth)
      ..get('/songs', (Request req) => _handleSongs(req, songs))
      ..get('/songs/<id>/stream', (Request req, String id) =>
          _handleStream(req, id, songs))
      ..get('/state', (Request req) =>
          _handleState(req, onPlayerStateRequested))
      ..get('/ws', webSocketHandler(_handleWebSocket));

    final handler = Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    final qrPayload = jsonEncode({
      'type': 'airpulse_connect',
      'url': 'http://$ip:$port',
      'sessionId': sessionId,
    });

    _activeSession = ServerSession(
      sessionId: sessionId,
      localIp: ip,
      port: port,
      status: ServerStatus.running,
      qrPayload: qrPayload,
      startedAt: DateTime.now(),
    );

    return _activeSession!;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _wsSource.dispose();
    _activeSession = null;
  }

  void broadcastPlayerState(Map<String, dynamic> state) {
    _wsSource.broadcast(state);
  }

  Response _handleRoot(Request req, String ip, int port, String sessionId) {
    final serverUrl = 'http://$ip:$port';
    final connectUrl = '$serverUrl/?session=$sessionId';
    final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AirPulse – Conectar</title>
  <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: system-ui, sans-serif;
      background: #0D1B2A;
      color: #fff;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 24px;
      padding: 32px 16px;
    }
    h1 { font-size: 1.6rem; letter-spacing: 1px; }
    p { color: #8899AA; font-size: 0.95rem; text-align: center; max-width: 360px; }
    #qr-box {
      background: #fff;
      border-radius: 16px;
      padding: 20px;
      box-shadow: 0 0 40px rgba(103,80,164,0.4);
    }
    .url {
      font-size: 0.8rem;
      color: #A78BFA;
      word-break: break-all;
      text-align: center;
      max-width: 360px;
    }
    .badge {
      background: #1A2D42;
      border-radius: 99px;
      padding: 6px 16px;
      font-size: 0.8rem;
      color: #8899AA;
    }
  </style>
</head>
<body>
  <h1>🎵 AirPulse</h1>
  <p>Escanea el código QR con tu móvil para conectarte al servidor de música.</p>
  <div id="qr-box">
    <canvas id="qr"></canvas>
  </div>
  <span class="url">$connectUrl</span>
  <span class="badge">Servidor activo · $ip:$port</span>
  <script>
    QRCode.toCanvas(document.getElementById('qr'), '$connectUrl', {
      width: 240,
      margin: 1,
      color: { dark: '#000000', light: '#ffffff' }
    });
  </script>
</body>
</html>''';
    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }

  Response _handleHealth(Request req) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'airpulse'}),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleSongs(Request req, List<Song> songs) {
    final list = songs
        .map((s) => {
              'id': s.id,
              'title': s.title,
              'artist': s.artist,
              'album': s.album,
              'durationMs': s.duration.inMilliseconds,
            })
        .toList();
    return Response.ok(
      jsonEncode(list),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleStream(Request req, String id, List<Song> songs) {
    final song = songs.where((s) => s.id == id).firstOrNull;
    if (song == null) return Response.notFound('Song not found');
    final file = File(song.filePath);
    if (!file.existsSync()) return Response.notFound('File not found');
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': 'audio/mpeg',
        'content-length': file.lengthSync().toString(),
        'accept-ranges': 'bytes',
      },
    );
  }

  Response _handleState(
    Request req,
    Function(Map<String, dynamic>)? callback,
  ) {
    final state = <String, dynamic>{'status': 'idle'};
    callback?.call(state);
    return Response.ok(
      jsonEncode(state),
      headers: {'content-type': 'application/json'},
    );
  }

  void _handleWebSocket(WebSocketChannel channel) {
    final clientId = _uuid.v4();
    _wsSource.registerClient(clientId, channel);
    channel.sink.add(jsonEncode({
      'type': 'welcome',
      'clientId': clientId,
    }));
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders());
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders());
      };
    };
  }

  Map<String, String> _corsHeaders() => {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, OPTIONS',
        'access-control-allow-headers': 'content-type',
      };

  Future<String> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP() ?? '127.0.0.1';
    } catch (_) {
      return '127.0.0.1';
    }
  }
}
