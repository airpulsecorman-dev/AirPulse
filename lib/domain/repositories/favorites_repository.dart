import '../entities/song.dart';

/// Contrato del repositorio de favoritos
///
/// Define las operaciones esenciales y avanzadas para gestionar
/// canciones favoritas en la aplicación.
abstract class FavoritesRepository {
  // Operaciones básicas
  Future<List<Song>> getFavorites(String userId);
  Future<void> addFavorite(String userId, Song song);
  Future<void> removeFavorite(String userId, String songId);
  Future<bool> isFavorite(String userId, String songId);

  // Operaciones avanzadas (opcionales, pueden retornar valores por defecto)
  Future<int> cleanInvalidFavorites(String userId) async => 0;
  Future<int> getFavoritesCount(String userId) async {
    final favorites = await getFavorites(userId);
    return favorites.length;
  }

  Future<List<Song>> searchFavorites(String userId, String query) async {
    final favorites = await getFavorites(userId);
    if (query.isEmpty) return favorites;

    final lowerQuery = query.toLowerCase();
    return favorites.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> clearAllFavorites(String userId) async {
    final favorites = await getFavorites(userId);
    for (final song in favorites) {
      await removeFavorite(userId, song.id);
    }
  }

  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final count = await getFavoritesCount(userId);
    return {'totalFavorites': count};
  }
}
