import '../../domain/entities/playlist.dart';
import 'song_model.dart';

class PlaylistModel extends Playlist {
  const PlaylistModel({
    required super.id,
    required super.name,
    super.songs,
    required super.createdAt,
    super.artworkPath,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((s) => SongModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      artworkPath: json['artworkPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => SongModel.fromEntity(s).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'artworkPath': artworkPath,
    };
  }
}
