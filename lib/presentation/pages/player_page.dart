import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../hooks/use_audio.dart';
import '../providers/favorites_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/repositories/player_repository.dart';
import '../../core/utils/duration_utils.dart';

enum _LyricsState { idle, loading, loaded, error }

class _LrcLine {
  final Duration timestamp;
  final String text;
  const _LrcLine(this.timestamp, this.text);
}

List<_LrcLine> _parseLrc(String lrc) {
  final lines = <_LrcLine>[];
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
  for (final line in lrc.split('\n')) {
    final match = regex.firstMatch(line);
    if (match == null) continue;
    final min = int.parse(match.group(1)!);
    final sec = int.parse(match.group(2)!);
    final raw = int.parse(match.group(3)!);
    final ms = match.group(3)!.length == 2 ? raw * 10 : raw;
    final text = match.group(4)!.trim();
    if (text.isEmpty) continue;
    lines.add(
      _LrcLine(Duration(minutes: min, seconds: sec, milliseconds: ms), text),
    );
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

Color _randomPastel() {
  final rng = Random();
  final hue = rng.nextDouble() * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.5, 0.80).toColor();
}

void showQueueSheet(BuildContext context, AudioHookResult audio) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final queue = audio.queue;
      final current = audio.currentSong;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cola de reproducción',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: queue.length,
                itemBuilder: (_, i) {
                  final song = queue[i];
                  final isCurrentSong = song.id == current?.id;
                  return ListTile(
                    leading: CircleAvatar(
                      child: isCurrentSong
                          ? const Icon(Icons.equalizer)
                          : Text('${i + 1}'),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrentSong
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentSong
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      audio.play(song, q: queue, index: i);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class PlayerPage extends HookWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = useAudio(context);
    final theme = Theme.of(context);
    final audioProvider = context.read<AudioProvider>();
    final accentColor = useState<Color>(_randomPastel());
    final lyricsState = useState<_LyricsState>(_LyricsState.idle);
    final lyrics = useState<String>('');
    final syncedLines = useState<List<_LrcLine>>([]);
    final songIdForLyrics = useRef<String>('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ahora suena'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) {
              final favs = context.watch<FavoritesProvider>();
              final userId = context.read<AuthProvider>().currentUser?.id ?? '';
              final isFav = audio.currentSong != null
                  ? favs.isFavorite(audio.currentSong!.id)
                  : false;
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF4D8B),
                ),
                tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                onPressed: audio.currentSong != null
                    ? () => favs.toggleFavorite(userId, audio.currentSong!)
                    : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Cola de reproducción',
            onPressed: () => showQueueSheet(context, audio),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: audio.currentSong == null
          ? const Center(child: Text('No hay canción en reproducción'))
          : AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.value.withValues(alpha: 0.35),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Album art / Lyrics swipeable
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: PageView(
                          onPageChanged: (page) async {
                            if (page != 1) return;
                            final song = audio.currentSong!;
                            if (songIdForLyrics.value == song.id &&
                                lyricsState.value != _LyricsState.idle)
                              return;
                            songIdForLyrics.value = song.id;
                            syncedLines.value = [];
                            lyrics.value = '';
                            lyricsState.value = _LyricsState.loading;
                            try {
                              final artist = Uri.encodeComponent(song.artist);
                              final title = Uri.encodeComponent(song.title);
                              final album = Uri.encodeComponent(song.album);
                              final secs = song.duration.inSeconds;
                              final uri = Uri.parse(
                                'https://lrclib.net/api/get?artist_name=$artist&track_name=$title&album_name=$album&duration=$secs',
                              );
                              final resp = await http
                                  .get(
                                    uri,
                                    headers: {'Lrclib-Client': 'AirPulse'},
                                  )
                                  .timeout(const Duration(seconds: 8));
                              if (resp.statusCode == 200) {
                                final data =
                                    jsonDecode(resp.body)
                                        as Map<String, dynamic>;
                                final synced = data['syncedLyrics'] as String?;
                                if (synced != null &&
                                    synced.trim().isNotEmpty) {
                                  syncedLines.value = _parseLrc(synced);
                                  lyricsState.value = _LyricsState.loaded;
                                } else {
                                  final plain = data['plainLyrics'] as String?;
                                  if (plain != null &&
                                      plain.trim().isNotEmpty) {
                                    lyrics.value = plain.trim();
                                    lyricsState.value = _LyricsState.loaded;
                                  } else {
                                    lyricsState.value = _LyricsState.error;
                                  }
                                }
                              } else {
                                lyricsState.value = _LyricsState.error;
                              }
                            } catch (_) {
                              lyricsState.value = _LyricsState.error;
                            }
                          },
                          children: [
                            // Página 1: portada
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: theme.colorScheme.primaryContainer,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 24,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: QueryArtworkWidget(
                                key: ValueKey(audio.currentSong!.id),
                                id: int.tryParse(audio.currentSong!.id) ?? 0,
                                type: ArtworkType.AUDIO,
                                artworkWidth: 260,
                                artworkHeight: 260,
                                artworkFit: BoxFit.cover,
                                artworkBorder: BorderRadius.circular(16),
                                keepOldArtwork: true,
                                nullArtworkWidget: Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            // Página 2: letras
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              clipBehavior: Clip.antiAlias,
                              padding: const EdgeInsets.all(12),
                              child: switch (lyricsState.value) {
                                _LyricsState.idle ||
                                _LyricsState.loading => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                _LyricsState.error => const Center(
                                  child: Text(
                                    'No se encontraron letras 🎵',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                _LyricsState.loaded =>
                                  syncedLines.value.isNotEmpty
                                      ? _LyricsView(
                                          lines: syncedLines.value,
                                          positionStream: audioProvider.positionStream,
                                        )
                                      : SingleChildScrollView(
                                          child: Text(
                                            lyrics.value,
                                            style: theme.textTheme.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Song info
                      Text(
                        audio.currentSong!.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        audio.currentSong!.artist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Seek bar — usa StreamBuilder para no reconstruir toda la página
                      StreamBuilder<Duration>(
                        stream: audioProvider.positionStream,
                        initialData: audio.position,
                        builder: (_, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final total = audio.currentSong!.duration;
                          return Column(
                            children: [
                              Slider(
                                value: playbackProgress(pos, total),
                                onChanged: (v) => audio.seek(
                                  Duration(
                                    milliseconds:
                                        (v * total.inMilliseconds).round(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(formatDuration(pos)),
                                    Text(formatDuration(total)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botón de tema pastel
                          Container(
                            decoration: BoxDecoration(
                              color: accentColor.value,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              tooltip: 'Cambiar color',
                              icon: Icon(
                                Icons.palette,
                                color: theme.colorScheme.onPrimary,
                              ),
                              onPressed: () {
                                accentColor.value = _randomPastel();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 36),
                            onPressed: audio.previous,
                          ),
                          FilledButton(
                            onPressed: audio.isPlaying
                                ? audio.pause
                                : audio.resume,
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Icon(
                              audio.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 36),
                            onPressed: audio.next,
                          ),
                          // Modo de reproducción: en orden → aleatorio → repetir todo → repetir una
                          Builder(
                            builder: (context) {
                              // Determina el modo actual combinando shuffle + repeatMode
                              // 0=en orden, 1=aleatorio, 2=repetir todo, 3=repetir una
                              final int currentMode;
                              if (audio.shuffleEnabled) {
                                currentMode = 1;
                              } else if (audio.repeatMode == RepeatMode.all) {
                                currentMode = 2;
                              } else if (audio.repeatMode == RepeatMode.one) {
                                currentMode = 3;
                              } else {
                                currentMode = 0;
                              }

                              final icons = [
                                Icons.format_list_numbered,
                                Icons.shuffle,
                                Icons.repeat,
                                Icons.repeat_one,
                              ];
                              final tooltips = [
                                'En orden',
                                'Aleatorio',
                                'Repetir todo',
                                'Repetir una',
                              ];

                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  tooltip: tooltips[currentMode],
                                  icon: Icon(
                                    icons[currentMode],
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final next = (currentMode + 1) % 4;
                                      // Desactivar shuffle si vamos a modo no-shuffle
                                      if (audio.shuffleEnabled && next != 1) {
                                        await audio.toggleShuffle();
                                      }
                                      switch (next) {
                                        case 0:
                                          await audio.setRepeatMode(
                                            RepeatMode.none,
                                          );
                                        case 1:
                                          await audio.setRepeatMode(
                                            RepeatMode.none,
                                          );
                                          await audio.toggleShuffle();
                                        case 2:
                                          await audio.setRepeatMode(
                                            RepeatMode.all,
                                          );
                                        case 3:
                                          await audio.setRepeatMode(
                                            RepeatMode.one,
                                          );
                                      }
                                    } catch (_) {}
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Volume
                      Row(
                        children: [
                          const Icon(Icons.volume_down),
                          Expanded(
                            child: Slider(
                              value: audio.volume,
                              onChanged: audio.setVolume,
                            ),
                          ),
                          const Icon(Icons.volume_up),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _LyricsView extends StatefulWidget {
  final List<_LrcLine> lines;
  final Stream<Duration> positionStream;

  const _LyricsView({required this.lines, required this.positionStream});

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  final _scroll = ScrollController();
  int _currentIndex = -1;
  static const _lineHeight = 48.0;
  StreamSubscription<Duration>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.positionStream.listen(_onPosition);
  }

  @override
  void didUpdateWidget(_LyricsView old) {
    super.didUpdateWidget(old);
    if (old.positionStream != widget.positionStream) {
      _sub?.cancel();
      _sub = widget.positionStream.listen(_onPosition);
    }
  }

  void _onPosition(Duration pos) {
    int idx = -1;
    for (int i = 0; i < widget.lines.length; i++) {
      if (widget.lines[i].timestamp <= pos) {
        idx = i;
      } else {
        break;
      }
    }
    if (idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      _scrollTo(idx);
    }
  }

  void _scrollTo(int idx) {
    if (!_scroll.hasClients || idx < 0) return;
    final target = (idx * _lineHeight) - 80.0;
    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      controller: _scroll,
      itemCount: widget.lines.length,
      itemExtent: _lineHeight,
      itemBuilder: (_, i) {
        final isCurrent = i == _currentIndex;
        return Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
              fontSize: isCurrent ? 15 : 13,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            child: Text(
              widget.lines[i].text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
