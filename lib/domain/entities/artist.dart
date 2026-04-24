import 'package:equatable/equatable.dart';
import 'song.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String? artworkPath;
  final List<Song> songs;

  const Artist({
    required this.id,
    required this.name,
    this.artworkPath,
    this.songs = const [],
  });

  @override
  List<Object?> get props => [id];
}
