import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration duration;
  final String? artworkPath;
  final int trackNumber;
  final DateTime? dateAdded;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.duration,
    this.artworkPath,
    this.trackNumber = 0,
    this.dateAdded,
  });

  @override
  List<Object?> get props => [id, filePath];
}
