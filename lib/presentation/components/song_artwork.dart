import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Widget que muestra el artwork de una canción.
/// En macOS usa [artworkPath] (archivo guardado en caché).
/// En Android/iOS usa [QueryArtworkWidget] con el ID de MediaStore.
class SongArtwork extends StatelessWidget {
  final String songId;
  final String? artworkPath;
  final double size;
  final double borderRadius;
  final Widget? nullWidget;

  const SongArtwork({
    super.key,
    required this.songId,
    this.artworkPath,
    this.size = 48,
    this.borderRadius = 24,
    this.nullWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = nullWidget ??
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );

    // En macOS usamos el archivo en caché
    if (Platform.isMacOS) {
      if (artworkPath != null) {
        final file = File(artworkPath!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
        );
      }
      return fallback;
    }

    // En Android/iOS usamos QueryArtworkWidget
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: int.tryParse(songId) ?? 0,
        type: ArtworkType.AUDIO,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.circular(borderRadius),
        keepOldArtwork: true,
        nullArtworkWidget: fallback,
      ),
    );
  }
}
