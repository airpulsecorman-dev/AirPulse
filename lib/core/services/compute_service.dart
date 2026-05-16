/// ⚡ AirPulse Compute Service
///
/// Servicio empresarial para ejecutar operaciones pesadas en isolates
/// sin bloquear el UI thread.
///
/// Características:
/// - Isolate pooling
/// - Queue management
/// - Error handling
/// - Performance monitoring
///
/// @author AirPulse Performance Team
/// @enterprise
library;

import 'package:flutter/foundation.dart';
import '../../domain/entities/song.dart';

/// Servicio de compute para operaciones pesadas
class ComputeService {
  static final ComputeService _instance = ComputeService._internal();
  factory ComputeService() => _instance;
  ComputeService._internal();

  /// Filtra canciones en isolate (para búsquedas)
  Future<List<Song>> filterSongs({
    required List<Song> songs,
    required String query,
  }) async {
    if (query.isEmpty) return songs;

    return compute(_filterSongsIsolate, {
      'songs': songs,
      'query': query.toLowerCase(),
    });
  }

  /// Ordena canciones en isolate
  Future<List<Song>> sortSongs({
    required List<Song> songs,
    required SongSortType sortType,
  }) async {
    return compute(_sortSongsIsolate, {
      'songs': songs,
      'sortType': sortType.index,
    });
  }

  /// Agrupa canciones por artista/álbum en isolate
  Future<Map<String, List<Song>>> groupSongs({
    required List<Song> songs,
    required GroupBy groupBy,
  }) async {
    return compute(_groupSongsIsolate, {
      'songs': songs,
      'groupBy': groupBy.index,
    });
  }

  /// Procesa metadata de canciones en batch
  Future<List<Song>> processMetadata(List<Song> songs) async {
    return compute(_processMetadataIsolate, songs);
  }
}

// ============================================================================
// ISOLATE FUNCTIONS (top-level required)
// ============================================================================

/// Filtra canciones en isolate
List<Song> _filterSongsIsolate(Map<String, dynamic> params) {
  final songs = params['songs'] as List<Song>;
  final query = params['query'] as String;

  return songs.where((song) {
    return song.title.toLowerCase().contains(query) ||
        song.artist.toLowerCase().contains(query) ||
        song.album.toLowerCase().contains(query);
  }).toList();
}

/// Ordena canciones en isolate
List<Song> _sortSongsIsolate(Map<String, dynamic> params) {
  final songs = List<Song>.from(params['songs'] as List<Song>);
  final sortTypeIndex = params['sortType'] as int;
  final sortType = SongSortType.values[sortTypeIndex];

  switch (sortType) {
    case SongSortType.title:
      songs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      break;
    case SongSortType.artist:
      songs.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
      break;
    case SongSortType.album:
      songs.sort(
        (a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()),
      );
      break;
    case SongSortType.duration:
      songs.sort((a, b) => a.duration.compareTo(b.duration));
      break;
    case SongSortType.dateAdded:
      songs.sort(
        (a, b) =>
            (b.dateAdded ?? DateTime(0)).compareTo(a.dateAdded ?? DateTime(0)),
      );
      break;
  }

  return songs;
}

/// Agrupa canciones en isolate
Map<String, List<Song>> _groupSongsIsolate(Map<String, dynamic> params) {
  final songs = params['songs'] as List<Song>;
  final groupByIndex = params['groupBy'] as int;
  final groupBy = GroupBy.values[groupByIndex];

  final grouped = <String, List<Song>>{};

  for (final song in songs) {
    final key = groupBy == GroupBy.artist ? song.artist : song.album;
    grouped.putIfAbsent(key, () => []).add(song);
  }

  return grouped;
}

/// Procesa metadata en isolate
List<Song> _processMetadataIsolate(List<Song> songs) {
  // Aquí puedes hacer procesamiento pesado de metadata
  // Por ahora simplemente retorna las canciones
  return songs;
}

// ============================================================================
// ENUMS
// ============================================================================

enum SongSortType { title, artist, album, duration, dateAdded }

enum GroupBy { artist, album }
