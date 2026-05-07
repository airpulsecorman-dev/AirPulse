import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:mime/mime.dart';
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

  /// Emite el clientId cada vez que se conecta un nuevo cliente WS.
  Stream<String> get newClientStream => _wsSource.newClientStream;
  ServerSession? get activeSession => _activeSession;

  /// Envía el estado actual solo al cliente que acaba de conectarse.
  void sendStateToClient(String clientId, Map<String, dynamic> state) {
    _wsSource.sendToClient(clientId, state);
  }

  Future<ServerSession> start({
    int port = 8765,
    List<Song> songs = const [],
    Function(Map<String, dynamic>)? onPlayerStateRequested,
  }) async {
    if (_server != null) await stop();

    final ip = await _getLocalIp();
    final sessionId = _uuid.v4();

    final router = Router()
      ..get('/health', _handleHealth)
      ..get('/songs', (Request req) => _handleSongs(req, songs))
      ..get(
        '/songs/<id>/stream',
        (Request req, String id) async => _handleStream(req, id, songs),
      )
      ..get(
        '/state',
        (Request req) => _handleState(req, onPlayerStateRequested),
      )
      ..get('/ws', webSocketHandler(_handleWebSocket));

    // Fallback: sirve la Flutter web app embebida en assets/web/
    final handler = Pipeline().addMiddleware(_corsMiddleware()).addHandler((
      Request req,
    ) async {
      final r = await router(req);
      // Si el router no manejó la ruta (404), intenta servir archivo estático
      if (r.statusCode == 404) {
        return _serveWebAsset(req);
      }
      return r;
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    // El QR apunta directamente al servidor del móvil (HTTP mismo origen).
    // Esto evita el bloqueo de mixed-content que ocurriría si la web
    // estuviera en HTTPS (GitHub Pages) haciendo peticiones a HTTP local.
    final serverUrl = 'http://$ip:$port';
    final qrPayload = serverUrl;

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

  /// Sirve los archivos est\u00e1ticos de la Flutter web app embebida en assets/web/.
  /// Permite cargar la PWA completa desde http://IP:port/ sin mixed-content.
  Future<Response> _serveWebAsset(Request request) async {
    var path = request.url.path;
    if (path.isEmpty || path == '/') path = 'index.html';
    // Eliminar query string si la tiene (service worker, etc.)
    path = path.split('?').first;

    final assetPath = 'assets/web/$path';
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
      return Response.ok(
        bytes,
        headers: {
          'content-type': mimeType,
          // Sin cache para HTML, service worker y manifest (cambios frecuentes)
          if (path.endsWith('.html') ||
              path.endsWith('.json') ||
              path.endsWith('_service_worker.js'))
            'cache-control': 'no-cache'
          else
            'cache-control': 'max-age=3600',
        },
      );
    } catch (_) {
      // Fallback: si no se encuentra el asset devuelve index.html (SPA routing)
      try {
        final data = await rootBundle.load('assets/web/index.html');
        final bytes = data.buffer.asUint8List();
        return Response.ok(
          bytes,
          headers: {
            'content-type': 'text/html; charset=utf-8',
            'cache-control': 'no-cache',
          },
        );
      } catch (_) {
        return Response.notFound('Not found');
      }
    }
  }

  Response _handleHealth(Request req) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'airpulse'}),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleSongs(Request req, List<Song> songs) {
    final list = songs
        .map(
          (s) => {
            'id': s.id,
            'title': s.title,
            'artist': s.artist,
            'album': s.album,
            'durationMs': s.duration.inMilliseconds,
          },
        )
        .toList();
    return Response.ok(
      jsonEncode(list),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleStream(
    Request req,
    String id,
    List<Song> songs,
  ) async {
    final song = songs.where((s) => s.id == id).firstOrNull;
    if (song == null) {
      dev.log(
        '[AirPulse] Stream: song $id NOT FOUND in list of ${songs.length}',
      );
      return Response.notFound('Song not found');
    }

    dev.log('[AirPulse] Stream: song "$id" path="${song.filePath}"');

    final file = File(song.filePath);
    final bool exists;
    try {
      exists = await file.exists();
    } catch (e) {
      dev.log('[AirPulse] Stream: exists() threw: $e');
      return Response.internalServerError(body: 'Cannot check file: $e');
    }

    if (!exists) {
      dev.log('[AirPulse] Stream: FILE NOT FOUND at "${song.filePath}"');
      return Response.notFound('File not found: ${song.filePath}');
    }

    final int fileSize;
    try {
      fileSize = await file.length();
    } catch (e) {
      dev.log('[AirPulse] Stream: length() threw: $e');
      return Response.internalServerError(body: 'Cannot read file length: $e');
    }

    final rangeInfo = req.headers['range'] ?? 'none';
    dev.log(
      '[AirPulse] Stream: serving ${song.filePath} ($fileSize bytes, range=$rangeInfo)',
    );

    final rangeHeader = req.headers['range'];

    // Soporte de Range requests para que el navegador pueda saltar en la pista
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = (parts.length > 1 && parts[1].isNotEmpty)
          ? int.tryParse(parts[1]) ?? (fileSize - 1)
          : fileSize - 1;
      final length = end - start + 1;
      return Response(
        206,
        body: file.openRead(start, end + 1),
        headers: {
          'content-type': _mimeType(song.filePath),
          'content-length': length.toString(),
          'content-range': 'bytes $start-$end/$fileSize',
          'accept-ranges': 'bytes',
        },
      );
    }

    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': _mimeType(song.filePath),
        'content-length': fileSize.toString(),
        'accept-ranges': 'bytes',
      },
    );
  }

  String _mimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    const map = {
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'wav': 'audio/wav',
    };
    return map[ext] ?? 'audio/mpeg';
  }

  Response _handleState(Request req, Function(Map<String, dynamic>)? callback) {
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
    channel.sink.add(jsonEncode({'type': 'welcome', 'clientId': clientId}));
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
    'access-control-allow-methods': 'GET, POST, OPTIONS, HEAD',
    'access-control-allow-headers':
        'content-type, range, access-control-request-private-network',
    'access-control-expose-headers':
        'content-range, content-length, accept-ranges',
    // Private Network Access (Chrome 94+): permite requests desde localhost
    // y otros orígenes públicos hacia IPs privadas (192.168.x.x)
    'access-control-allow-private-network': 'true',
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
