import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../domain/entities/song.dart';
import '../../core/utils/duration_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: QueryArtworkWidget(
            id: int.tryParse(song.id) ?? 0,
            type: ArtworkType.AUDIO,
            artworkWidth: 48,
            artworkHeight: 48,
            artworkFit: BoxFit.cover,
            artworkBorder: BorderRadius.circular(24),
            keepOldArtwork: true,
            nullArtworkWidget: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: isPlaying
                  ? Icon(Icons.equalizer, color: theme.colorScheme.primary)
                  : Icon(Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer),
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
          Text(
            formatDuration(song.duration),
            style: theme.textTheme.bodySmall,
          ),
          if (onMoreTap != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFFF4D8B) : null,
              ),
              onPressed: onMoreTap,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
