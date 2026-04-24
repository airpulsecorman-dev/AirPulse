import 'package:equatable/equatable.dart';
import 'song.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final String? artworkPath;

  const Playlist({
    required this.id,
    required this.name,
    this.songs = const [],
    required this.createdAt,
    this.artworkPath,
  });

  Playlist copyWith({
    String? name,
    List<Song>? songs,
    String? artworkPath,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }

  @override
  List<Object?> get props => [id];
}
