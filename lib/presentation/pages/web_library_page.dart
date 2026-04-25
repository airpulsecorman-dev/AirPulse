import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/duration_utils.dart' as dur_utils;
import '../../data/models/song_model.dart';
import '../../domain/entities/song.dart';

/// Página web que se conecta al servidor AirPulse del móvil,
/// lista sus canciones y las reproduce desde el navegador.
class WebLibraryPage extends StatefulWidget {
  final String serverUrl;

  const WebLibraryPage({super.key, required this.serverUrl});

  @override
  State<WebLibraryPage> createState() => _WebLibraryPageState();
}

class _WebLibraryPageState extends State<WebLibraryPage> {
  final AudioPlayer _player = AudioPlayer();
  WebSocketChannel? _ws;

  List<Song> _songs = [];
  Song? _currentSong;
  bool _isLoading = true;
  String? _error;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  int _wsRetryDelay = 1;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _connectWebSocket();
    _posSub = _player.positionStream.listen(
        (p) => setState(() => _position = p));
    _durSub = _player.durationStream.listen(
        (d) => setState(() => _duration = d ?? Duration.zero));
    _playSub = _player.playingStream.listen(
        (playing) => setState(() => _isPlaying = playing));
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _player.dispose();
    _ws?.sink.close();
    super.dispose();
  }

  Future<void> _fetchSongs() async {
    try {
      final uri = Uri.parse('${widget.serverUrl}/songs');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List;
        setState(() {
          _songs = data
              .map((e) => SongModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error del servidor: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor móvil.\n'
            'Verifica que el móvil esté en la misma red y el servidor esté activo.';
        _isLoading = false;
      });
    }
  }

  void _connectWebSocket() {
    try {
      final wsUrl = widget.serverUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      _ws = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));
      _ws!.stream.listen(
        (_) {},
        onDone: _scheduleWsReconnect,
        onError: (_) => _scheduleWsReconnect(),
      );
      _wsRetryDelay = 1;
    } catch (_) {
      _scheduleWsReconnect();
    }
  }

  void _scheduleWsReconnect() {
    if (!mounted) return;
    Future.delayed(Duration(seconds: _wsRetryDelay), () {
      if (!mounted) return;
      _ws?.sink.close();
      _wsRetryDelay = (_wsRetryDelay * 2).clamp(1, 30);
      _connectWebSocket();
    });
  }

  Future<void> _playSong(Song song, int index) async {
    setState(() => _currentSong = song);
    final streamUrl = '${widget.serverUrl}/songs/${song.id}/stream';
    await _player.setUrl(streamUrl);
    await _player.play();

    // Notificar al móvil vía WebSocket (control remoto)
    _ws?.sink.add(jsonEncode({
      'type': 'play',
      'songId': song.id,
      'index': index,
    }));
  }

  void _sendCommand(String type) {
    _ws?.sink.add(jsonEncode({'type': type}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2D42),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.music_note_rounded,
                color: Color(0xFFFF4D8B), size: 22),
            const SizedBox(width: 8),
            const Text('AirPulse',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '— ${widget.serverUrl}',
                style: const TextStyle(
                    color: Color(0xFF8899AA), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar canciones',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchSongs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFF4D8B)))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _fetchSongs)
              : Column(
                  children: [
                    Expanded(child: _buildSongList(theme)),
                    if (_currentSong != null)
                      _PlayerBar(
                        song: _currentSong!,
                        isPlaying: _isPlaying,
                        position: _position,
                        duration: _duration,
                        onPlay: _player.play,
                        onPause: _player.pause,
                        onSeek: (d) => _player.seek(d),
                        onPrev: () {
                          final idx = _songs.indexOf(_currentSong!);
                          if (idx > 0) _playSong(_songs[idx - 1], idx - 1);
                          _sendCommand('previous');
                        },
                        onNext: () {
                          final idx = _songs.indexOf(_currentSong!);
                          if (idx < _songs.length - 1) {
                            _playSong(_songs[idx + 1], idx + 1);
                          }
                          _sendCommand('next');
                        },
                      ),
                  ],
                ),
    );
  }

  Widget _buildSongList(ThemeData theme) {
    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_outlined,
                size: 64, color: Color(0xFF8899AA)),
            const SizedBox(height: 16),
            Text('No hay canciones en el servidor',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (_, i) {
        final song = _songs[i];
        final isActive = _currentSong?.id == song.id;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive
                ? const Color(0xFFFF4D8B)
                : const Color(0xFF1A2D42),
            child: isActive && _isPlaying
                ? const Icon(Icons.equalizer,
                    color: Colors.white, size: 18)
                : Icon(Icons.music_note,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF8899AA),
                    size: 18),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              color: isActive ? const Color(0xFFFF4D8B) : Colors.white,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${song.artist} • ${song.album}',
            style:
                const TextStyle(color: Color(0xFF8899AA), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            dur_utils.formatDuration(song.duration),
            style: const TextStyle(
                color: Color(0xFF8899AA), fontSize: 12),
          ),
          onTap: () => _playSong(song, i),
        );
      },
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;

  const _PlayerBar({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlay,
    required this.onPause,
    required this.onPrev,
    required this.onNext,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
    final current =
        position.inMilliseconds.toDouble().clamp(0.0, total);

    return Container(
      color: const Color(0xFF1A2D42),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF4D8B),
              inactiveTrackColor: const Color(0xFF334455),
              thumbColor: const Color(0xFFFF4D8B),
              overlayColor:
                  const Color(0xFFFF4D8B).withValues(alpha: 0.2),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: current,
              min: 0,
              max: total,
              onChanged: (v) => onSeek(Duration(milliseconds: v.toInt())),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(
                          color: Color(0xFF8899AA), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${dur_utils.formatDuration(position)} / ${dur_utils.formatDuration(duration)}',
                style: const TextStyle(
                    color: Color(0xFF8899AA), fontSize: 11),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white),
                onPressed: onPrev,
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: const Color(0xFFFF4D8B),
                  size: 40,
                ),
                onPressed: isPlaying ? onPause : onPlay,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Color(0xFF8899AA)),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8899AA)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D8B),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
