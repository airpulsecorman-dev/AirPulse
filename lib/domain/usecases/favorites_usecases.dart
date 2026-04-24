import '../../domain/entities/song.dart';
import '../repositories/favorites_repository.dart';

class GetFavoritesUseCase {
  final FavoritesRepository _repo;
  GetFavoritesUseCase(this._repo);

  Future<List<Song>> call(String userId) => _repo.getFavorites(userId);
}

class AddFavoriteUseCase {
  final FavoritesRepository _repo;
  AddFavoriteUseCase(this._repo);

  Future<void> call(String userId, Song song) =>
      _repo.addFavorite(userId, song);
}

class RemoveFavoriteUseCase {
  final FavoritesRepository _repo;
  RemoveFavoriteUseCase(this._repo);

  Future<void> call(String userId, String songId) =>
      _repo.removeFavorite(userId, songId);
}

class IsFavoriteUseCase {
  final FavoritesRepository _repo;
  IsFavoriteUseCase(this._repo);

  Future<bool> call(String userId, String songId) =>
      _repo.isFavorite(userId, songId);
}
