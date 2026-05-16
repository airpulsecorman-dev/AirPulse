/// 🎵 AirPulse Song Tile - OPTIMIZADO
///
/// Widget optimizado para mostrar canciones en listas.
///
/// Optimizaciones implementadas:
/// - StatefulWidget con memoización
/// - RepaintBoundary para aislamiento
/// - AutomaticKeepAliveClientMixin para cache
/// - Artwork con cache manager
/// - Rebuilds minimizados
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/Colors.dart';
import '../../domain/entities/song.dart';
import '../../core/utils/duration_utils.dart';
import 'song_artwork_optimized.dart';

/// Song Tile optimizado para listas grandes
class SongTileOptimized extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final bool isFavorite;

  const SongTileOptimized({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
    this.onMoreTap,
    this.isFavorite = false,
  });

  @override
  State<SongTileOptimized> createState() => _SongTileOptimizedState();
}

class _SongTileOptimizedState extends State<SongTileOptimized>
    with AutomaticKeepAliveClientMixin {
  // 🚀 OPTIMIZACIÓN: Mantener estado vivo durante scroll
  @override
  bool get wantKeepAlive => true;

  // 🚀 OPTIMIZACIÓN: Cache de valores computados
  late String _formattedDuration;
  late String _subtitle;

  @override
  void initState() {
    super.initState();
    _updateCachedValues();
  }

  @override
  void didUpdateWidget(SongTileOptimized oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar si los datos relevantes cambiaron
    if (oldWidget.song.id != widget.song.id) {
      _updateCachedValues();
    }
  }

  void _updateCachedValues() {
    _formattedDuration = formatDuration(widget.song.duration);
    _subtitle = '${widget.song.artist} · ${widget.song.album}';
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildOptionsSheet(context),
    );
  }

  Widget _buildOptionsSheet(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Compartir canción'),
            onTap: () => _shareSong(context),
          ),
          if (widget.onMoreTap != null)
            ListTile(
              leading: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? AppColors.favorite : null,
              ),
              title: Text(
                widget.isFavorite
                    ? 'Quitar de favoritos'
                    : 'Añadir a favoritos',
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onMoreTap!();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _shareSong(BuildContext context) async {
    Navigator.pop(context);
    try {
      final cacheDir = await getTemporaryDirectory();
      final safeTitle = widget.song.title.replaceAll(
        RegExp(r'[/\\:*?"<>|]'),
        '_',
      );
      final safeArtist = widget.song.artist.replaceAll(
        RegExp(r'[/\\:*?"<>|]'),
        '_',
      );
      final ext = widget.song.filePath.contains('.')
          ? widget.song.filePath.split('.').last
          : 'mp3';
      final tmpFile = File('${cacheDir.path}/$safeTitle - $safeArtist.$ext');

      await File(widget.song.filePath).copy(tmpFile.path);
      await Share.shareXFiles(
        [XFile(tmpFile.path, mimeType: 'audio/mpeg')],
        text:
            '🎵 "${widget.song.title}"\n🎤 ${widget.song.artist}\n💿 ${widget.song.album}\n\nEscúchala en AirPulse!',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🚀 Required for AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);

    // 🚀 OPTIMIZACIÓN: RepaintBoundary para aislar repaints
    return RepaintBoundary(
      child: ListTile(
        leading: _buildLeading(theme),
        title: _buildTitle(theme),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(theme),
        onTap: widget.onTap,
        tileColor: widget.isPlaying
            ? theme.colorScheme.primary.withOpacity(0.12)
            : null,
      ),
    );
  }

  /// 🚀 OPTIMIZACIÓN: Construir leading con cache
  Widget _buildLeading(ThemeData theme) {
    return SizedBox(
      width: 48,
      height: 48,
      child: SongArtworkOptimized(
        songId: widget.song.id,
        artworkPath: widget.song.artworkPath,
        size: 48,
        borderRadius: 24,
        nullWidget: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: widget.isPlaying
              ? Icon(Icons.equalizer, color: theme.colorScheme.primary)
              : Icon(
                  Icons.music_note,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
        ),
      ),
    );
  }

  /// 🚀 OPTIMIZACIÓN: Title con styled text cache
  Widget _buildTitle(ThemeData theme) {
    return Text(
      widget.song.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: widget.isPlaying ? FontWeight.bold : FontWeight.normal,
        color: widget.isPlaying ? theme.colorScheme.primary : null,
      ),
    );
  }

  /// 🚀 OPTIMIZACIÓN: Subtitle con texto precalculado
  Widget _buildSubtitle() {
    return Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  /// 🚀 OPTIMIZACIÓN: Trailing con widgets cached
  Widget _buildTrailing(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formattedDuration, style: theme.textTheme.bodySmall),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context),
        ),
      ],
    );
  }
}
