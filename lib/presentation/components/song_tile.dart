import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/song.dart';
import '../../core/utils/duration_utils.dart';
import 'song_artwork.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final bool isFavorite;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
    this.onMoreTap,
    this.isFavorite = false,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir canción'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    // Copiar al directorio temporal para que FileProvider pueda exponerlo
                    final cacheDir = await getTemporaryDirectory();
                    final safeTitle = song.title.replaceAll(
                      RegExp(r'[/\\:*?"<>|]'),
                      '_',
                    );
                    final safeArtist = song.artist.replaceAll(
                      RegExp(r'[/\\:*?"<>|]'),
                      '_',
                    );
                    final ext = song.filePath.contains('.')
                        ? song.filePath.split('.').last
                        : 'mp3';
                    final tmpFile = File(
                      '${cacheDir.path}/$safeTitle - $safeArtist.$ext',
                    );
                    await File(song.filePath).copy(tmpFile.path);
                    await Share.shareXFiles(
                      [XFile(tmpFile.path, mimeType: 'audio/mpeg')],
                      text:
                          '🎵 "${song.title}"\n🎤 ${song.artist}\n💿 ${song.album}\n\nEscúchala en AirPulse!',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al compartir: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              if (onMoreTap != null)
                ListTile(
                  leading: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFFF4D8B) : null,
                  ),
                  title: Text(
                    isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onMoreTap!();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: SongArtwork(
          songId: song.id,
          artworkPath: song.artworkPath,
          size: 48,
          borderRadius: 24,
          nullWidget: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: isPlaying
                ? Icon(Icons.equalizer, color: theme.colorScheme.primary)
                : Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        '${song.artist} · ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatDuration(song.duration), style: theme.textTheme.bodySmall),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      onTap: onTap,
      tileColor: isPlaying ? theme.colorScheme.primary.withOpacity(0.12) : null,
    );
  }
}
