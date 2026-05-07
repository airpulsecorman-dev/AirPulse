// ─── AirPulse PWA ─────────────────────────────────────────────────────────────
// Módulo principal: conexión WebSocket, reproducción de audio, caché offline.

// ─── Utils ────────────────────────────────────────────────────────────────────
function formatTime(ms) {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const sec = (s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

function qs(sel) { return document.querySelector(sel); }
function show(el) { el.classList.remove('hidden'); el.classList.add('active'); }
function hide(el) { el.classList.add('hidden'); el.classList.remove('active'); }

// ─── State ────────────────────────────────────────────────────────────────────
const state = {
  serverUrl: null,
  sessionId: null,
  ws: null,
  audio: new Audio(),
  songs: [],
  currentSong: null,
  isPlaying: false,
  repeatMode: 'none',   // 'none' | 'all' | 'one'
  shuffleEnabled: false,
  currentIndex: 0,
  volume: 1,
  cachedSongs: new Map(),  // songId → blobURL
};

// ─── Cache (IndexedDB) ────────────────────────────────────────────────────────
class AudioCache {
  constructor() { this.db = null; }

  async open() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open('airpulse-cache', 1);
      req.onupgradeneeded = e => {
        e.target.result.createObjectStore('songs', { keyPath: 'id' });
      };
      req.onsuccess = e => { this.db = e.target.result; resolve(); };
      req.onerror = () => reject(req.error);
    });
  }

  async get(id) {
    return new Promise(resolve => {
      const tx = this.db.transaction('songs', 'readonly');
      const req = tx.objectStore('songs').get(id);
      req.onsuccess = () => resolve(req.result?.blob ?? null);
      req.onerror = () => resolve(null);
    });
  }

  async put(id, blob) {
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction('songs', 'readwrite');
      const req = tx.objectStore('songs').put({ id, blob });
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }
}

const cache = new AudioCache();

// ─── WebSocket ────────────────────────────────────────────────────────────────
function connectWS(serverUrl) {
  const wsUrl = serverUrl.replace('http://', 'ws://') + '/ws';
  state.ws = new WebSocket(wsUrl);

  state.ws.onopen = () => {
    setConnectionStatus(true);
    console.log('[WS] Conectado');
  };

  state.ws.onmessage = ({ data }) => {
    try {
      const msg = JSON.parse(data);
      handleServerMessage(msg);
    } catch {}
  };

  state.ws.onclose = () => {
    setConnectionStatus(false);
    setTimeout(() => connectWS(serverUrl), 3000);
  };

  state.ws.onerror = () => state.ws.close();
}

function sendCommand(type, payload = {}) {
  if (state.ws?.readyState === WebSocket.OPEN) {
    state.ws.send(JSON.stringify({ type, ...payload }));
  }
}

function handleServerMessage(msg) {
  switch (msg.type) {
    case 'player_state':
      syncPlayerState(msg);
      break;
    case 'welcome':
      console.log('[WS] Bienvenido, clientId:', msg.clientId);
      break;
  }
}

function syncPlayerState(msg) {
  // Sincronizar metadatos de canción
  if (msg.songId && msg.songId !== state.currentSong?.id) {
    const song = state.songs.find(s => s.id === msg.songId);
    if (song) {
      state.currentSong = song;
      state.currentIndex = msg.currentIndex ?? state.songs.indexOf(song);
      updateSongInfo(song);
      renderSongList();
    }
  }
  if (msg.songTitle) {
    qs('#song-title').textContent = msg.songTitle ?? '—';
    qs('#song-artist').textContent = msg.songArtist ?? '—';
    if (qs('#song-album')) qs('#song-album').textContent = msg.songAlbum ?? '';
  }

  // Sincronizar estado reproducción
  if (typeof msg.isPlaying === 'boolean') {
    if (msg.isPlaying && state.audio.paused && state.currentSong) {
      state.audio.play().catch(() => {});
    } else if (!msg.isPlaying && !state.audio.paused) {
      state.audio.pause();
    }
    state.isPlaying = msg.isPlaying;
    updatePlayButton();
  }

  // Sincronizar posición (solo si diferencia > 3 s para evitar saltos)
  if (typeof msg.positionMs === 'number' && state.audio.duration) {
    const serverPosSec = msg.positionMs / 1000;
    if (Math.abs(state.audio.currentTime - serverPosSec) > 3) {
      state.audio.currentTime = serverPosSec;
    }
  }

  // Sincronizar repeatMode y shuffle
  if (msg.repeatMode) state.repeatMode = msg.repeatMode;
  if (typeof msg.shuffleEnabled === 'boolean') state.shuffleEnabled = msg.shuffleEnabled;
}

// ─── Audio Playback ───────────────────────────────────────────────────────────
async function playSong(song, index) {
  state.currentSong = song;
  state.currentIndex = index;
  updateSongInfo(song);

  let src;
  const cached = await cache.get(song.id);
  if (cached) {
    src = URL.createObjectURL(cached);
  } else {
    src = `${state.serverUrl}/songs/${song.id}/stream`;
    // Cachear en background
    fetch(src)
      .then(r => r.blob())
      .then(blob => cache.put(song.id, blob))
      .catch(() => {});
  }

  state.audio.src = src;
  state.audio.volume = state.volume;
  await state.audio.play();
  state.isPlaying = true;
  updatePlayButton();
  renderSongList();
}

function updateSongInfo(song) {
  qs('#song-title').textContent = song.title;
  qs('#song-artist').textContent = song.artist;
  qs('#song-album').textContent = song.album ?? '';
}

function updatePlayButton() {
  qs('#btn-play-pause').textContent = state.isPlaying ? '⏸' : '▶';
}

function togglePlayPause() {
  if (state.isPlaying) {
    state.audio.pause();
    state.isPlaying = false;
  } else {
    state.audio.play();
    state.isPlaying = true;
  }
  updatePlayButton();
  sendCommand('control', { action: state.isPlaying ? 'resume' : 'pause' });
}

function playNext() {
  let idx = state.currentIndex + 1;
  if (state.shuffleEnabled) idx = Math.floor(Math.random() * state.songs.length);
  if (idx >= state.songs.length) {
    if (state.repeatMode === 'all') idx = 0;
    else return;
  }
  playSong(state.songs[idx], idx);
  sendCommand('control', { action: 'next' });
}

function playPrev() {
  let idx = state.currentIndex - 1;
  if (idx < 0) idx = state.songs.length - 1;
  playSong(state.songs[idx], idx);
  sendCommand('control', { action: 'previous' });
}

// ─── Library ──────────────────────────────────────────────────────────────────
async function fetchSongs() {
  try {
    const res = await fetch(`${state.serverUrl}/songs`);
    state.songs = await res.json();
    renderSongList();
  } catch (e) {
    console.warn('[Library] Error al cargar canciones', e);
  }
}

function renderSongList(filter = '') {
  const list = qs('#song-list');
  const q = filter.toLowerCase();
  const filtered = q
    ? state.songs.filter(s =>
        s.title.toLowerCase().includes(q) ||
        s.artist.toLowerCase().includes(q))
    : state.songs;

  list.innerHTML = filtered.map((song, i) => `
    <li class="${song.id === state.currentSong?.id ? 'playing' : ''}"
        data-idx="${state.songs.indexOf(song)}">
      <span class="song-num">${song.id === state.currentSong?.id ? '▶' : i + 1}</span>
      <div class="song-details">
        <div class="s-title">${song.title}</div>
        <div class="s-artist">${song.artist}</div>
      </div>
      <span class="s-dur">${formatTime(song.durationMs)}</span>
    </li>
  `).join('');

  list.querySelectorAll('li').forEach(li => {
    li.addEventListener('click', () => {
      const idx = +li.dataset.idx;
      playSong(state.songs[idx], idx);
      sendCommand('control', { action: 'play', songId: state.songs[idx].id });
    });
  });
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
state.audio.addEventListener('timeupdate', () => {
  const { currentTime, duration } = state.audio;
  if (!duration) return;
  qs('#seek-bar').value = (currentTime / duration) * 100;
  qs('#time-current').textContent = formatTime(currentTime * 1000);
  qs('#time-total').textContent = formatTime(duration * 1000);
});

state.audio.addEventListener('ended', () => {
  if (state.repeatMode === 'one') {
    state.audio.currentTime = 0;
    state.audio.play();
  } else {
    playNext();
  }
});

qs('#seek-bar').addEventListener('input', e => {
  const pct = e.target.value / 100;
  state.audio.currentTime = state.audio.duration * pct;
});

qs('#volume-bar').addEventListener('input', e => {
  state.volume = +e.target.value;
  state.audio.volume = state.volume;
});

// ─── UI Controls ─────────────────────────────────────────────────────────────
qs('#btn-play-pause').addEventListener('click', togglePlayPause);
qs('#btn-next').addEventListener('click', playNext);
qs('#btn-prev').addEventListener('click', playPrev);

qs('#btn-shuffle').addEventListener('click', () => {
  state.shuffleEnabled = !state.shuffleEnabled;
  qs('#btn-shuffle').classList.toggle('active', state.shuffleEnabled);
  sendCommand('control', { action: 'shuffle' });
});

qs('#btn-repeat').addEventListener('click', () => {
  const modes = ['none', 'all', 'one'];
  const idx = modes.indexOf(state.repeatMode);
  state.repeatMode = modes[(idx + 1) % modes.length];
  const icons = { none: '🔁', all: '🔁', one: '🔂' };
  qs('#btn-repeat').textContent = icons[state.repeatMode];
  qs('#btn-repeat').classList.toggle('active', state.repeatMode !== 'none');
  sendCommand('control', { action: 'repeat', mode: state.repeatMode });
});

qs('#search-input').addEventListener('input', e => renderSongList(e.target.value));

// ─── Connection Flow ──────────────────────────────────────────────────────────
function setConnectionStatus(connected) {
  const dot = qs('#conn-dot');
  dot.classList.toggle('disconnected', !connected);
  if (!connected) showOfflineBanner();
  else qs('#offline-banner').classList.add('hidden');
}

function showOfflineBanner() {
  qs('#offline-banner').classList.remove('hidden');
}

async function connect(url) {
  state.serverUrl = url.replace(/\/$/, '');
  qs('#server-info-label').textContent = state.serverUrl;

  try {
    const res = await fetch(`${state.serverUrl}/health`, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) throw new Error('Server unhealthy');
  } catch (e) {
    showConnectError('No se pudo conectar al servidor: ' + e.message);
    return;
  }

  hide(qs('#screen-connect'));
  show(qs('#screen-player'));

  connectWS(state.serverUrl);
  await fetchSongs();
  localStorage.setItem('airpulse-last-url', state.serverUrl);
}

function showConnectError(msg) {
  const el = qs('#connect-error');
  el.textContent = msg;
  el.classList.remove('hidden');
}

qs('#btn-connect').addEventListener('click', async () => {
  const url = qs('#server-url').value.trim();
  if (!url) { showConnectError('Ingresa la URL del servidor'); return; }
  qs('#connect-error').classList.add('hidden');
  await connect(url);
});

qs('#btn-disconnect').addEventListener('click', () => {
  state.ws?.close();
  state.audio.pause();
  state.isPlaying = false;
  hide(qs('#screen-player'));
  show(qs('#screen-connect'));
});

// ─── Offline detection ────────────────────────────────────────────────────────
window.addEventListener('offline', showOfflineBanner);
window.addEventListener('online', () => {
  qs('#offline-banner').classList.add('hidden');
  if (state.serverUrl) connectWS(state.serverUrl);
});

// ─── Handle QR deep-link (?url=...)  ─────────────────────────────────────────
const params = new URLSearchParams(location.search);
const deepUrl = params.get('url');
if (deepUrl) {
  qs('#server-url').value = deepUrl;
  connect(deepUrl);
} else {
  const last = localStorage.getItem('airpulse-last-url');
  if (last) qs('#server-url').value = last;
}

// ─── Init ─────────────────────────────────────────────────────────────────────
(async () => {
  await cache.open();
  show(qs('#screen-connect'));
})();
