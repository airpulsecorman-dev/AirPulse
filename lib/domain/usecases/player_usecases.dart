import '../entities/song.dart';
import '../repositories/player_repository.dart';

class PlaySongUseCase {
  final PlayerRepository _repository;
  PlaySongUseCase(this._repository);
  Future<void> call(Song song) => _repository.play(song);
}

class SetQueueUseCase {
  final PlayerRepository _repository;
  SetQueueUseCase(this._repository);
  Future<void> call(List<Song> songs, {int startIndex = 0}) =>
      _repository.setQueue(songs, startIndex: startIndex);
}

class SeekUseCase {
  final PlayerRepository _repository;
  SeekUseCase(this._repository);
  Future<void> call(Duration position) => _repository.seek(position);
}
