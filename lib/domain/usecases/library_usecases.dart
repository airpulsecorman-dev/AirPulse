import '../entities/song.dart';
import '../repositories/library_repository.dart';

class GetLibraryUseCase {
  final LibraryRepository _repository;
  GetLibraryUseCase(this._repository);
  Future<List<Song>> call() => _repository.getAllSongs();
}

class SearchSongsUseCase {
  final LibraryRepository _repository;
  SearchSongsUseCase(this._repository);
  Future<List<Song>> call(String query) => _repository.searchSongs(query);
}

class CreatePlaylistUseCase {
  final LibraryRepository _repository;
  CreatePlaylistUseCase(this._repository);
  Future<void> call(String name) => _repository.createPlaylist(name);
}
