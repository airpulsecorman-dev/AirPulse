import '../../domain/entities/album.dart';
import 'song_model.dart';

class AlbumModel extends Album {
  const AlbumModel({
    required super.id,
    required super.title,
    required super.artist,
    super.artworkPath,
    super.year,
    super.songs,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      artworkPath: json['artworkPath'] as String?,
      year: json['year'] as int? ?? 0,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((s) => SongModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkPath': artworkPath,
      'year': year,
      'songs': songs.map((s) => SongModel.fromEntity(s).toJson()).toList(),
    };
  }
}
