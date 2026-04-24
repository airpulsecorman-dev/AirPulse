import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/favorites_usecases.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repo;

  List<Song> _favorites = [];
  bool _isLoading = false;

  FavoritesProvider(this._repo);

  List<Song> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites(String userId) async {
    _isLoading = true;
    notifyListeners();
    _favorites = await GetFavoritesUseCase(_repo).call(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String userId, Song song) async {
    final isFav = await IsFavoriteUseCase(_repo).call(userId, song.id);
    if (isFav) {
      await RemoveFavoriteUseCase(_repo).call(userId, song.id);
      _favorites.removeWhere((s) => s.id == song.id);
    } else {
      await AddFavoriteUseCase(_repo).call(userId, song);
      _favorites = [..._favorites, song];
    }
    notifyListeners();
  }

  bool isFavorite(String songId) => _favorites.any((s) => s.id == songId);

  void clear() {
    _favorites = [];
    notifyListeners();
  }
}
