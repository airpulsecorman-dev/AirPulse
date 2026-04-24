import 'package:equatable/equatable.dart';
import 'song.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? artworkPath;
  final int year;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkPath,
    this.year = 0,
    this.songs = const [],
  });

  @override
  List<Object?> get props => [id];
}
