import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
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
      ..get('/', (Request req) => _handleRoot(req, ip, port, sessionId))
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
    final html = _buildPlayerHtml(serverUrl);
    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  // ── HTML del reproductor web ──────────────────────────────────────────────
  String _buildPlayerHtml(String base) =>
      '''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>AirPulse</title>
<style>
:root{
  --bg:#0D1B2A;--surface:#112233;--surface2:#1A2D42;--border:#1E3550;
  --accent:#FF4D8B;--accent2:#FF80AB;--text:#EAEFF5;--muted:#8899AA;
  --radius:12px;--player-h:88px;
}
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
html,body{height:100%;overflow:hidden}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;
  background:var(--bg);color:var(--text);display:flex;flex-direction:column}

/* ── TOPBAR ── */
#topbar{
  height:56px;background:var(--surface2);border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding:0 16px;gap:10px;flex-shrink:0;
  box-shadow:0 2px 12px #0006;z-index:10;
}
#topbar .logo{display:flex;align-items:center;gap:8px;text-decoration:none}
#topbar h1{font-size:1.1rem;font-weight:800;letter-spacing:1.5px;
  background:linear-gradient(135deg,var(--accent),var(--accent2));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
#ws-dot{width:8px;height:8px;border-radius:50%;background:var(--muted);
  transition:background .4s;flex-shrink:0;margin-left:auto}
#ws-dot.ok{background:#4CAF50;box-shadow:0 0 6px #4CAF5088}
#ws-dot.err{background:var(--accent);box-shadow:0 0 6px var(--accent)88}
#ws-label{font-size:.72rem;color:var(--muted);transition:color .4s}

/* ── SEARCH BAR ── */
#searchbar{
  padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);
  flex-shrink:0;display:none;
}
#searchbar input{
  width:100%;background:var(--surface2);border:1px solid var(--border);
  border-radius:24px;padding:8px 16px;color:var(--text);font-size:.9rem;
  outline:none;transition:border-color .2s;
}
#searchbar input:focus{border-color:var(--accent)}
#searchbar input::placeholder{color:var(--muted)}

/* ── STATUS PILL ── */
#statuspill{
  margin:0 16px;flex-shrink:0;display:none;
  padding:5px 12px;border-radius:20px;font-size:.72rem;
  background:var(--surface2);color:var(--muted);text-align:center;
}
#statuspill.ok{color:#4CAF50}#statuspill.err{color:var(--accent)}

/* ── MAIN AREA ── */
#main{flex:1;display:flex;overflow:hidden;min-height:0}

/* ── SIDEBAR (desktop) ── */
#sidebar{
  width:260px;flex-shrink:0;background:var(--surface);border-right:1px solid var(--border);
  display:flex;flex-direction:column;overflow:hidden;
}
#sidebar-header{
  padding:16px;display:flex;align-items:center;justify-content:space-between;
  border-bottom:1px solid var(--border);flex-shrink:0;
}
#sidebar-header span{font-size:.8rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
#count-badge{
  font-size:.72rem;background:var(--accent);color:#fff;
  padding:2px 8px;border-radius:10px;font-weight:700;
}

/* ── SONG LIST ── */
#list{flex:1;overflow-y:auto;padding:4px 0}
#list::-webkit-scrollbar{width:4px}
#list::-webkit-scrollbar-track{background:transparent}
#list::-webkit-scrollbar-thumb{background:var(--border);border-radius:2px}
.song{
  display:flex;align-items:center;gap:10px;padding:9px 14px;cursor:pointer;
  border-radius:8px;margin:1px 6px;transition:background .15s,transform .1s;
  position:relative;
}
.song:hover{background:var(--surface2)}
.song:active{transform:scale(.99)}
.song.active{background:linear-gradient(90deg,#FF4D8B18,transparent);
  box-shadow:inset 2px 0 0 var(--accent)}
.song .art{
  width:40px;height:40px;border-radius:8px;flex-shrink:0;
  background:var(--surface2);display:flex;align-items:center;justify-content:center;
  overflow:hidden;position:relative;
}
.song .art svg{opacity:.4}
.song.active .art{box-shadow:0 0 0 2px var(--accent)44}
.song .idx{
  position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
  font-size:.75rem;color:var(--muted);font-weight:500;
}
.song.active .idx,.song:hover .idx{opacity:0}
.song .art .play-ico{
  position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
  opacity:0;transition:opacity .15s;
}
.song:hover .art .play-ico,.song.active .art .play-ico{opacity:1}
.song .info{flex:1;min-width:0}
.song .title{
  font-size:.875rem;font-weight:500;white-space:nowrap;
  overflow:hidden;text-overflow:ellipsis;
}
.song .sub{
  font-size:.75rem;color:var(--muted);white-space:nowrap;
  overflow:hidden;text-overflow:ellipsis;margin-top:1px;
}
.song.active .title{color:var(--accent);font-weight:600}
.song .dur{font-size:.72rem;color:var(--muted);flex-shrink:0;padding-left:6px}

/* ── CONTENT AREA ── */
#content{
  flex:1;display:flex;flex-direction:column;align-items:center;
  justify-content:center;overflow:hidden;padding:24px;
  background:radial-gradient(ellipse at 50% 0%,#1A2D4266,transparent 70%);
}
#now-art{
  width:min(220px,45vw);height:min(220px,45vw);border-radius:var(--radius);
  background:var(--surface2);display:flex;align-items:center;justify-content:center;
  box-shadow:0 20px 60px #00000066;overflow:hidden;flex-shrink:0;
  transition:box-shadow .4s;
}
#now-art.playing{box-shadow:0 20px 60px #FF4D8B44,0 0 0 2px var(--accent)33}
#now-art svg{opacity:.25;width:60px;height:60px}
#now-info{margin-top:20px;text-align:center;padding:0 8px;max-width:100%}
#now-title{
  font-size:1.15rem;font-weight:700;white-space:nowrap;
  overflow:hidden;text-overflow:ellipsis;
}
#now-artist{font-size:.85rem;color:var(--muted);margin-top:4px;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

/* ── LOADING / EMPTY ── */
#loading{
  position:absolute;inset:0;display:flex;flex-direction:column;
  align-items:center;justify-content:center;gap:16px;
  background:var(--bg);z-index:20;transition:opacity .3s;
}
#loading.hidden{opacity:0;pointer-events:none}
.spinner{
  width:40px;height:40px;border:3px solid var(--border);
  border-top-color:var(--accent);border-radius:50%;
  animation:spin .8s linear infinite;
}
@keyframes spin{to{transform:rotate(360deg)}}
#empty-msg{color:var(--muted);font-size:.9rem;margin-top:8px}

/* ── BOTTOM PLAYER BAR ── */
#player{
  height:var(--player-h);background:var(--surface2);
  border-top:1px solid var(--border);
  display:none;flex-direction:column;justify-content:center;
  padding:0 16px;flex-shrink:0;
  box-shadow:0 -4px 24px #00000044;
}
#player.visible{display:flex}

/* progress */
#prog-wrap{
  height:3px;background:var(--border);border-radius:2px;
  cursor:pointer;margin-bottom:8px;position:relative;
  transition:height .15s;
}
#prog-wrap:hover{height:5px}
#prog{
  height:100%;background:linear-gradient(90deg,var(--accent),var(--accent2));
  border-radius:2px;width:0%;transition:width .25s linear;pointer-events:none;
  position:relative;
}
#prog::after{
  content:'';position:absolute;right:-5px;top:50%;transform:translateY(-50%);
  width:10px;height:10px;border-radius:50%;background:var(--accent);
  opacity:0;transition:opacity .15s;
}
#prog-wrap:hover #prog::after{opacity:1}
#time-row{display:flex;justify-content:space-between;margin-bottom:6px}
#time-row span{font-size:.68rem;color:var(--muted)}

/* player content */
#player-inner{display:flex;align-items:center;gap:12px}
#player-art{
  width:44px;height:44px;border-radius:8px;flex-shrink:0;
  background:var(--surface);display:flex;align-items:center;justify-content:center;
  overflow:hidden;
}
#player-art svg{opacity:.4;width:22px;height:22px}
#player-info{flex:1;min-width:0}
#p-title{font-size:.875rem;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#p-sub{font-size:.75rem;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:2px}
#controls{display:flex;align-items:center;gap:4px;flex-shrink:0}
.ctrl-btn{
  background:none;border:none;color:var(--text);cursor:pointer;
  width:36px;height:36px;border-radius:50%;
  display:flex;align-items:center;justify-content:center;
  transition:background .15s,color .15s;flex-shrink:0;
}
.ctrl-btn:hover{background:var(--surface);color:var(--accent)}
#btn-play{
  width:44px;height:44px;border-radius:50%;
  background:var(--accent);color:#fff;border:none;cursor:pointer;
  display:flex;align-items:center;justify-content:center;
  transition:transform .1s,background .15s;box-shadow:0 4px 12px var(--accent)66;
  flex-shrink:0;
}
#btn-play:hover{background:var(--accent2);transform:scale(1.05)}
#btn-play:active{transform:scale(.97)}
#vol-wrap{
  display:flex;align-items:center;gap:6px;flex-shrink:0;
  width:90px;margin-left:4px;
}
@media(max-width:520px){#vol-wrap{display:none}}
#vol{flex:1;accent-color:var(--accent);height:3px;cursor:pointer}

/* ── MOBILE: hide sidebar, show list below ── */
@media(max-width:640px){
  #sidebar{width:100%;border-right:none;border-bottom:1px solid var(--border);
    max-height:55vh;position:relative}
  #content{display:none}
  #main{flex-direction:column}
  #sidebar-header{padding:10px 12px}
}
@media(min-width:641px){
  #statuspill{display:none!important}
}
</style>
</head>
<body>

<!-- TOPBAR -->
<div id="topbar">
  <a class="logo" href="#">
    <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--accent)"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
    <h1>AirPulse</h1>
  </a>
  <div id="statuspill"></div>
  <div style="margin-left:auto;display:flex;align-items:center;gap:6px">
    <div id="ws-dot"></div>
    <span id="ws-label">conectando</span>
  </div>
</div>

<!-- SEARCH -->
<div id="searchbar">
  <input id="q" type="search" placeholder="🔍  Buscar canción, artista o álbum…" oninput="filter()" autocomplete="off">
</div>

<!-- MAIN -->
<div id="main">
  <!-- Sidebar / list -->
  <div id="sidebar">
    <div id="sidebar-header">
      <span>Biblioteca</span>
      <span id="count-badge" style="display:none">0</span>
    </div>
    <div id="list"></div>
  </div>

  <!-- Content: now playing -->
  <div id="content">
    <div id="now-art">
      <svg viewBox="0 0 24 24" fill="var(--text)"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
    </div>
    <div id="now-info">
      <div id="now-title">Selecciona una canción</div>
      <div id="now-artist">—</div>
    </div>
  </div>
</div>

<!-- LOADING OVERLAY -->
<div id="loading">
  <div class="spinner"></div>
  <div id="empty-msg">Conectando al servidor…</div>
</div>

<!-- PLAYER BAR -->
<div id="player">
  <div id="prog-wrap" id="pw">
    <div id="prog"></div>
  </div>
  <div id="time-row"><span id="t-cur">0:00</span><span id="t-dur">0:00</span></div>
  <div id="player-inner">
    <div id="player-art">
      <svg viewBox="0 0 24 24" fill="var(--text)"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
    </div>
    <div id="player-info">
      <div id="p-title">—</div>
      <div id="p-sub">—</div>
    </div>
    <div id="controls">
      <button class="ctrl-btn" onclick="prevSong()" title="Anterior (←)">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6 8.5 6V6z"/></svg>
      </button>
      <button id="btn-play" onclick="togglePlay()" title="Play/Pausa (Space)">
        <svg id="ico-play" width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
        <svg id="ico-pause" width="22" height="22" viewBox="0 0 24 24" fill="currentColor" style="display:none"><path d="M6 19h4V5H6zm8-14v14h4V5z"/></svg>
      </button>
      <button class="ctrl-btn" onclick="nextSong()" title="Siguiente (→)">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zm2-8.14L11.03 12 8 14.14V9.86zM16 6h2v12h-2z"/></svg>
      </button>
    </div>
    <div id="vol-wrap">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="var(--muted)"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/></svg>
      <input id="vol" type="range" min="0" max="1" step="0.02" value="1" oninput="audio.volume=+this.value">
    </div>
  </div>
</div>

<audio id="audio" preload="none"></audio>

<script>
const BASE = '$base';
const audio = document.getElementById('audio');
let songs = [], filtered = [], currentIdx = -1;
let wsDelay = 1000;

// ─── WebSocket ────────────────────────────────────────────────
let ws;
function connectWS() {
  const url = BASE.replace(/^http/, 'ws') + '/ws';
  ws = new WebSocket(url);
  ws.onopen = () => {
    setWs(true);
    wsDelay = 1000;
  };
  ws.onmessage = e => {
    try { const m = JSON.parse(e.data); applyState(m); } catch(_){}
  };
  ws.onclose = () => {
    setWs(false);
    setTimeout(connectWS, wsDelay);
    wsDelay = Math.min(wsDelay * 2, 30000);
  };
  ws.onerror = () => ws.close();
}
function setWs(ok) {
  const dot = document.getElementById('ws-dot');
  const lbl = document.getElementById('ws-label');
  dot.className = ok ? 'ok' : 'err';
  lbl.textContent = ok ? 'conectado' : 'sin conexión';
  lbl.style.color = ok ? '#4CAF50' : 'var(--accent)';
}
function sendWS(obj) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
}

// ─── Canciones ────────────────────────────────────────────────
async function fetchSongs() {
  try {
    const r = await fetch(BASE + '/songs');
    if (!r.ok) throw new Error(r.status);
    songs = await r.json();
    filtered = songs;
    render();
    hideLoading();
    document.getElementById('searchbar').style.display = '';
    const badge = document.getElementById('count-badge');
    badge.textContent = songs.length;
    badge.style.display = '';
    showStatus(songs.length + ' canciones · conectado', true);
  } catch(e) {
    document.getElementById('empty-msg').textContent = 'Error al conectar. Reintentando…';
    setTimeout(fetchSongs, 5000);
  }
}

function filter() {
  const q = document.getElementById('q').value.toLowerCase();
  filtered = q ? songs.filter(s =>
    (s.title||'').toLowerCase().includes(q) ||
    (s.artist||'').toLowerCase().includes(q) ||
    (s.album||'').toLowerCase().includes(q)
  ) : songs;
  render();
}

function render() {
  const list = document.getElementById('list');
  if (!filtered.length) {
    list.innerHTML = '<div style="text-align:center;padding:32px;color:var(--muted)">Sin resultados</div>';
    return;
  }
  list.innerHTML = filtered.map((s, i) => {
    const gi = songs.indexOf(s);
    const active = gi === currentIdx;
    return \`<div class="song\${active ? ' active' : ''}" onclick="playSong(\${gi})">
      <div class="art">
        <span class="idx">\${i+1}</span>
        <span class="play-ico">
          \${active
            ? '<svg width="18" height="18" viewBox="0 0 24 24" fill="var(--accent)"><path d="M6 19h4V5H6zm8-14v14h4V5z"/></svg>'
            : '<svg width="18" height="18" viewBox="0 0 24 24" fill="var(--accent)"><path d="M8 5v14l11-7z"/></svg>'
          }
        </span>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="var(--text)"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></svg>
      </div>
      <div class="info">
        <div class="title">\${esc(s.title)}</div>
        <div class="sub">\${esc(s.artist)} · \${esc(s.album)}</div>
      </div>
      <span class="dur">\${fmtMs(s.durationMs)}</span>
    </div>\`;
  }).join('');
}

// ─── Reproducción ─────────────────────────────────────────────
function playSong(idx) {
  if (idx < 0 || idx >= songs.length) return;
  currentIdx = idx;
  const s = songs[idx];
  audio.src = BASE + '/songs/' + s.id + '/stream';
  audio.load();
  audio.play().catch(()=>{});
  updateNowPlaying(s);
  render();
  sendWS({ type: 'play', songId: s.id, index: idx });
}

function updateNowPlaying(s) {
  document.getElementById('p-title').textContent = s.title || '—';
  document.getElementById('p-sub').textContent = (s.artist||'') + ' · ' + (s.album||'');
  document.getElementById('now-title').textContent = s.title || '—';
  document.getElementById('now-artist').textContent = s.artist || '—';
  document.getElementById('player').classList.add('visible');
  document.title = s.title + ' — AirPulse';
  if ('mediaSession' in navigator) {
    navigator.mediaSession.metadata = new MediaMetadata({
      title: s.title || '',
      artist: s.artist || '',
      album: s.album || '',
    });
  }
}

function togglePlay() {
  if (audio.paused) { audio.play(); sendWS({type:'resume'}); }
  else { audio.pause(); sendWS({type:'pause'}); }
}
function prevSong() { if (currentIdx > 0) playSong(currentIdx - 1); }
function nextSong() { if (currentIdx < songs.length - 1) playSong(currentIdx + 1); }

// progress seek
document.getElementById('prog-wrap').addEventListener('click', e => {
  const r = e.currentTarget.getBoundingClientRect();
  audio.currentTime = ((e.clientX - r.left) / r.width) * (audio.duration || 0);
});

// ─── Sync estado desde móvil ──────────────────────────────────
function applyState(msg) {
  if (!msg || !msg.type) return;
  if (msg.type !== 'state' && msg.type !== 'player_state') return;
  if (msg.songId) {
    const idx = songs.findIndex(s => s.id === msg.songId);
    if (idx !== -1 && idx !== currentIdx) {
      currentIdx = idx;
      const s = songs[idx];
      audio.src = BASE + '/songs/' + s.id + '/stream';
      audio.load();
      updateNowPlaying(s);
      render();
    }
  }
  if (typeof msg.isPlaying === 'boolean') {
    if (msg.isPlaying && audio.paused) audio.play().catch(()=>{});
    else if (!msg.isPlaying && !audio.paused) audio.pause();
  }
  if (typeof msg.positionMs === 'number' && audio.duration) {
    const t = msg.positionMs / 1000;
    if (Math.abs(audio.currentTime - t) > 3) audio.currentTime = t;
  }
}

// ─── Eventos audio ────────────────────────────────────────────
audio.addEventListener('play', () => {
  document.getElementById('ico-play').style.display = 'none';
  document.getElementById('ico-pause').style.display = '';
  document.getElementById('now-art').classList.add('playing');
});
audio.addEventListener('pause', () => {
  document.getElementById('ico-play').style.display = '';
  document.getElementById('ico-pause').style.display = 'none';
  document.getElementById('now-art').classList.remove('playing');
});
audio.addEventListener('timeupdate', () => {
  const c = audio.currentTime, d = audio.duration || 0;
  document.getElementById('prog').style.width = (d ? c/d*100 : 0) + '%';
  document.getElementById('t-cur').textContent = fmt(c);
  document.getElementById('t-dur').textContent = fmt(d);
});
audio.addEventListener('ended', nextSong);
if ('mediaSession' in navigator) {
  navigator.mediaSession.setActionHandler('previoustrack', prevSong);
  navigator.mediaSession.setActionHandler('nexttrack', nextSong);
}

// ─── Teclado ──────────────────────────────────────────────────
document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT') return;
  if (e.code === 'Space') { e.preventDefault(); togglePlay(); }
  if (e.code === 'ArrowRight') nextSong();
  if (e.code === 'ArrowLeft') prevSong();
});

// ─── Utils ────────────────────────────────────────────────────
function fmt(s) {
  if (!isFinite(s)) return '0:00';
  return Math.floor(s/60) + ':' + String(Math.floor(s%60)).padStart(2,'0');
}
function fmtMs(ms) { return fmt((ms||0)/1000); }
function esc(s) {
  return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function hideLoading() {
  const el = document.getElementById('loading');
  el.classList.add('hidden');
  setTimeout(() => el.remove(), 400);
}
function showStatus(msg, ok) {
  const el = document.getElementById('statuspill');
  el.textContent = msg;
  el.className = ok ? 'ok' : 'err';
  el.style.display = 'block';
}

// ─── Inicio ───────────────────────────────────────────────────
connectWS();
fetchSongs();
</script>
</body>
</html>''';

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
