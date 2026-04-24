import '../entities/song.dart';

abstract class FavoritesRepository {
  Future<List<Song>> getFavorites(String userId);
  Future<void> addFavorite(String userId, Song song);
  Future<void> removeFavorite(String userId, String songId);
  Future<bool> isFavorite(String userId, String songId);
}
