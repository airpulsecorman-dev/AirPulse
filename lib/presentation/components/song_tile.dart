import 'package:flutter/material.dart';
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
                : Icon(Icons.music_note,
                    color: theme.colorScheme.onPrimaryContainer),
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
      tileColor: isPlaying
          ? theme.colorScheme.primary.withOpacity(0.12)
          : null,
    );
  }
}
