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
      ..get(
        '/songs/<id>/stream',
        (Request req, String id) => _handleStream(req, id, songs),
      )
      ..get(
        '/state',
        (Request req) => _handleState(req, onPlayerStateRequested),
      )
      ..get('/ws', webSocketHandler(_handleWebSocket));

    final handler = Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);

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

  Response _handleRoot(Request req, String ip, int port, String sessionId) {
    final serverUrl = 'http://$ip:$port';
    // Reproductor HTML+JS completo servido desde el móvil.
    // Al ser mismo origen (HTTP→HTTP) no hay bloqueo de mixed-content.
    final html =
        '''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AirPulse</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:#0D1B2A;color:#fff;min-height:100vh;display:flex;flex-direction:column}
#header{background:#1A2D42;padding:14px 20px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #334455}
#header h1{font-size:1.1rem;font-weight:700;letter-spacing:1px;color:#FF4D8B}
#header span{font-size:.75rem;color:#8899AA;margin-left:auto}
#status{padding:6px 12px;font-size:.75rem;background:#1A2D42;color:#8899AA;text-align:center;border-bottom:1px solid #334455}
#status.ok{color:#4CAF50}#status.err{color:#FF4D8B}
#search{padding:10px 16px;background:#1A2D42;border-bottom:1px solid #334455}
#search input{width:100%;background:#0D1B2A;border:1px solid #334455;border-radius:8px;padding:8px 12px;color:#fff;font-size:.9rem;outline:none}
#search input:focus{border-color:#FF4D8B}
#list{flex:1;overflow-y:auto;padding:8px 0}
.song{display:flex;align-items:center;gap:12px;padding:10px 16px;cursor:pointer;border-bottom:1px solid #1A2D42;transition:background .15s}
.song:hover{background:#1A2D42}
.song.active{background:#1A2D421f;border-left:3px solid #FF4D8B}
.song .idx{width:28px;text-align:right;font-size:.8rem;color:#8899AA;flex-shrink:0}
.song .info{flex:1;min-width:0}
.song .title{font-size:.9rem;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.song .sub{font-size:.75rem;color:#8899AA;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.song.active .title{color:#FF4D8B}
.song .dur{font-size:.75rem;color:#8899AA;flex-shrink:0}
#player{background:#1A2D42;border-top:1px solid #334455;padding:10px 16px 14px}
#player .info{font-size:.85rem;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-bottom:6px}
#player .sub{font-size:.75rem;color:#8899AA;margin-bottom:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#prog-wrap{position:relative;height:4px;background:#334455;border-radius:2px;cursor:pointer;margin-bottom:10px}
#prog{height:4px;background:#FF4D8B;border-radius:2px;width:0%;pointer-events:none}
#controls{display:flex;align-items:center;gap:8px;justify-content:center}
#controls button{background:none;border:none;color:#fff;cursor:pointer;padding:6px;border-radius:50%;transition:background .15s;line-height:0}
#controls button:hover{background:#334455}
#btn-play{color:#FF4D8B}
#time{font-size:.73rem;color:#8899AA;display:flex;justify-content:space-between;margin-top:4px}
#vol-wrap{display:flex;align-items:center;gap:6px;margin-top:8px}
#vol-wrap svg{color:#8899AA;flex-shrink:0}
#vol{flex:1;accent-color:#FF4D8B}
#empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;color:#8899AA;text-align:center;padding:32px}
#loading{flex:1;display:flex;align-items:center;justify-content:center;gap:12px;color:#8899AA}
.spin{animation:spin 1s linear infinite;display:inline-block}
@keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<div id="header">
  <svg width="22" height="22" viewBox="0 0 24 24" fill="#FF4D8B"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
  <h1>AirPulse</h1>
  <span id="ws-badge">●&nbsp;conectando…</span>
</div>
<div id="status">Cargando canciones…</div>
<div id="search" style="display:none"><input id="q" placeholder="Buscar canción, artista o álbum…" oninput="filter()"></div>
<div id="loading"><span class="spin">⏳</span> Cargando…</div>
<div id="empty" style="display:none">
  <svg width="48" height="48" viewBox="0 0 24 24" fill="#8899AA"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
  <p>No se encontraron canciones</p>
</div>
<div id="list" style="display:none"></div>
<div id="player" style="display:none">
  <div class="info" id="p-title">—</div>
  <div class="sub" id="p-sub">—</div>
  <div id="prog-wrap" onclick="seek(event)"><div id="prog"></div></div>
  <div id="time"><span id="t-cur">0:00</span><span id="t-dur">0:00</span></div>
  <div id="controls">
    <button onclick="prevSong()" title="Anterior">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6 8.5 6V6z"/></svg>
    </button>
    <button id="btn-play" onclick="togglePlay()" title="Play/Pausa">
      <svg id="ico-play" width="36" height="36" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
      <svg id="ico-pause" width="36" height="36" viewBox="0 0 24 24" fill="currentColor" style="display:none"><path d="M6 19h4V5H6zm8-14v14h4V5z"/></svg>
    </button>
    <button onclick="nextSong()" title="Siguiente">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zm2-8.14L11.03 12 8 14.14V9.86zM16 6h2v12h-2z"/></svg>
    </button>
  </div>
  <div id="vol-wrap">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/></svg>
    <input id="vol" type="range" min="0" max="1" step="0.02" value="1" oninput="audio.volume=this.value">
  </div>
</div>

<audio id="audio" preload="none"></audio>

<script>
const BASE = '$serverUrl';
const audio = document.getElementById('audio');
let songs = [], filtered = [], currentIdx = -1;
let wsRetryDelay = 1000, wsRetryTimer = null;

// ── WebSocket ─────────────────────────────────────────────────
let ws;
function connectWS() {
  const wsUrl = BASE.replace('http://', 'ws://') + '/ws';
  ws = new WebSocket(wsUrl);
  ws.onopen = () => {
    document.getElementById('ws-badge').textContent = '● conectado';
    document.getElementById('ws-badge').style.color = '#4CAF50';
    wsRetryDelay = 1000;
  };
  ws.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      if (msg.type === 'state') applyState(msg);
    } catch(_) {}
  };
  ws.onclose = () => {
    document.getElementById('ws-badge').textContent = '● desconectado';
    document.getElementById('ws-badge').style.color = '#FF4D8B';
    wsRetryTimer = setTimeout(() => connectWS(), wsRetryDelay);
    wsRetryDelay = Math.min(wsRetryDelay * 2, 30000);
  };
  ws.onerror = () => ws.close();
}
function sendWS(obj) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
}

// ── Canciones ─────────────────────────────────────────────────
async function fetchSongs() {
  setStatus('Cargando canciones del móvil…', false);
  try {
    const r = await fetch(BASE + '/songs');
    if (!r.ok) throw new Error('HTTP ' + r.status);
    songs = await r.json();
    filtered = songs;
    render();
    setStatus('✓ ' + songs.length + ' canciones · ' + BASE, true);
    document.getElementById('search').style.display = '';
    document.getElementById('loading').style.display = 'none';
    document.getElementById('list').style.display = '';
  } catch(e) {
    document.getElementById('loading').style.display = 'none';
    setStatus('Error al conectar con el móvil. ¿Están en la misma red WiFi?', false);
    document.getElementById('empty').style.display = 'flex';
    // Reintentar en 5 segundos
    setTimeout(fetchSongs, 5000);
  }
}

function filter() {
  const q = document.getElementById('q').value.toLowerCase();
  filtered = q ? songs.filter(s =>
    s.title.toLowerCase().includes(q) ||
    s.artist.toLowerCase().includes(q) ||
    s.album.toLowerCase().includes(q)
  ) : songs;
  render();
}

function render() {
  const list = document.getElementById('list');
  const empty = document.getElementById('empty');
  if (!filtered.length) { list.innerHTML = ''; empty.style.display = 'flex'; return; }
  empty.style.display = 'none';
  list.innerHTML = filtered.map((s, i) => `
    <div class="song\${currentIdx === songs.indexOf(s) ? ' active' : ''}" onclick="playSong(\${songs.indexOf(s)})">
      <span class="idx">\${i+1}</span>
      <div class="info">
        <div class="title">\${esc(s.title)}</div>
        <div class="sub">\${esc(s.artist)} · \${esc(s.album)}</div>
      </div>
      <span class="dur">\${fmtMs(s.durationMs)}</span>
    </div>`).join('');
}

function esc(s) {
  return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ── Reproducción ──────────────────────────────────────────────
function playSong(idx) {
  if (idx < 0 || idx >= songs.length) return;
  currentIdx = idx;
  const song = songs[idx];
  audio.src = BASE + '/songs/' + song.id + '/stream';
  audio.load();
  audio.play().catch(() => {});
  document.getElementById('player').style.display = '';
  document.getElementById('p-title').textContent = song.title;
  document.getElementById('p-sub').textContent = song.artist + ' · ' + song.album;
  render();
  sendWS({ type: 'play', songId: song.id, index: idx });
}

function togglePlay() {
  if (audio.paused) { audio.play(); sendWS({ type: 'resume' }); }
  else { audio.pause(); sendWS({ type: 'pause' }); }
}

function prevSong() {
  if (currentIdx > 0) playSong(currentIdx - 1);
}

function nextSong() {
  if (currentIdx < songs.length - 1) playSong(currentIdx + 1);
}

function seek(e) {
  const rect = e.currentTarget.getBoundingClientRect();
  const ratio = (e.clientX - rect.left) / rect.width;
  audio.currentTime = ratio * (audio.duration || 0);
}

function applyState(msg) {
  // Sincronizar estado si el móvil controla la reproducción
}

// ── Eventos audio ─────────────────────────────────────────────
audio.addEventListener('play', () => {
  document.getElementById('ico-play').style.display = 'none';
  document.getElementById('ico-pause').style.display = '';
});
audio.addEventListener('pause', () => {
  document.getElementById('ico-play').style.display = '';
  document.getElementById('ico-pause').style.display = 'none';
});
audio.addEventListener('timeupdate', () => {
  const cur = audio.currentTime, dur = audio.duration || 0;
  document.getElementById('prog').style.width = (dur ? cur/dur*100 : 0) + '%';
  document.getElementById('t-cur').textContent = fmt(cur);
  document.getElementById('t-dur').textContent = fmt(dur);
});
audio.addEventListener('ended', () => nextSong());
audio.addEventListener('error', () => {
  setStatus('Error al cargar la canción. Intenta con otra.', false);
});

// ── Utilidades ────────────────────────────────────────────────
function fmt(s) {
  if (!isFinite(s)) return '0:00';
  const m = Math.floor(s/60), sec = Math.floor(s%60);
  return m + ':' + String(sec).padStart(2,'0');
}
function fmtMs(ms) { return fmt((ms||0)/1000); }
function setStatus(msg, ok) {
  const el = document.getElementById('status');
  el.textContent = msg;
  el.className = ok ? 'ok' : (msg.includes('Error') ? 'err' : '');
}

// ── Inicio ────────────────────────────────────────────────────
connectWS();
fetchSongs();
</script>
</body>
</html>''';
    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
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

  Response _handleStream(Request req, String id, List<Song> songs) {
    final song = songs.where((s) => s.id == id).firstOrNull;
    if (song == null) return Response.notFound('Song not found');
    final file = File(song.filePath);
    if (!file.existsSync()) return Response.notFound('File not found');

    final fileSize = file.lengthSync();
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
    'access-control-allow-headers': 'content-type, range',
    'access-control-expose-headers':
        'content-range, content-length, accept-ranges',
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
