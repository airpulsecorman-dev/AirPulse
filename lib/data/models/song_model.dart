import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.album,
    required super.filePath,
    required super.duration,
    super.artworkPath,
    super.trackNumber,
    super.dateAdded,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      filePath: json['filePath'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      artworkPath: json['artworkPath'] as String?,
      trackNumber: json['trackNumber'] as int? ?? 0,
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'durationMs': duration.inMilliseconds,
      'artworkPath': artworkPath,
      'trackNumber': trackNumber,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  factory SongModel.fromEntity(Song song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      filePath: song.filePath,
      duration: song.duration,
      artworkPath: song.artworkPath,
      trackNumber: song.trackNumber,
      dateAdded: song.dateAdded,
    );
  }
}
