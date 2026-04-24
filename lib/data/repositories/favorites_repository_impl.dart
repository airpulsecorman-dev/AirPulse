import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../models/song_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  static const _prefix = 'airpulse_favorites_';

  String _key(String userId) => '$_prefix$userId';

  Future<List<SongModel>> _load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(String userId, List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode(songs.map((s) => s.toJson()).toList()),
    );
  }

  @override
  Future<List<Song>> getFavorites(String userId) => _load(userId);

  @override
  Future<void> addFavorite(String userId, Song song) async {
    final list = await _load(userId);
    if (list.any((s) => s.id == song.id)) return;
    list.add(SongModel.fromEntity(song));
    await _save(userId, list);
  }

  @override
  Future<void> removeFavorite(String userId, String songId) async {
    final list = await _load(userId);
    list.removeWhere((s) => s.id == songId);
    await _save(userId, list);
  }

  @override
  Future<bool> isFavorite(String userId, String songId) async {
    final list = await _load(userId);
    return list.any((s) => s.id == songId);
  }
}
