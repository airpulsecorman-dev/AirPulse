import '../../domain/entities/song.dart';
import '../sources/local/favorites_database.dart';

/// Modelo de datos para mapear canciones favoritas en SQLite
///
/// Responsabilidades:
/// - Conversión bidireccional entre entidad Song y tabla SQLite
/// - Validación de datos antes de persistir
/// - Serialización/deserialización optimizada
/// - Manejo de campos nullable y valores por defecto
class FavoriteSongModel {
  final int? id; // ID de la tabla SQLite (auto-incremental)
  final String userId;
  final String songId;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final int durationMs;
  final String? artworkPath;
  final int trackNumber;
  final String? dateAdded;
  final String? createdAt;

  const FavoriteSongModel({
    this.id,
    required this.userId,
    required this.songId,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.durationMs,
    this.artworkPath,
    this.trackNumber = 0,
    this.dateAdded,
    this.createdAt,
  });

  /// Crea un modelo desde una fila de SQLite
  ///
  /// Convierte los tipos de datos de SQLite (Map<String, dynamic>)
  /// a un objeto FavoriteSongModel tipado
  factory FavoriteSongModel.fromMap(Map<String, dynamic> map) {
    return FavoriteSongModel(
      id: map[FavoritesDatabase.columnId] as int?,
      userId: map[FavoritesDatabase.columnUserId] as String,
      songId: map[FavoritesDatabase.columnSongId] as String,
      title: map[FavoritesDatabase.columnTitle] as String,
      artist: map[FavoritesDatabase.columnArtist] as String,
      album: map[FavoritesDatabase.columnAlbum] as String,
      filePath: map[FavoritesDatabase.columnFilePath] as String,
      durationMs: map[FavoritesDatabase.columnDuration] as int,
      artworkPath: map[FavoritesDatabase.columnArtworkPath] as String?,
      trackNumber: map[FavoritesDatabase.columnTrackNumber] as int? ?? 0,
      dateAdded: map[FavoritesDatabase.columnDateAdded] as String?,
      createdAt: map[FavoritesDatabase.columnCreatedAt] as String?,
    );
  }

  /// Convierte el modelo a un Map para insertar en SQLite
  ///
  /// Omite el ID para permitir auto-incremento en inserciones nuevas
  /// Incluye el ID para actualizaciones
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      FavoritesDatabase.columnUserId: userId,
      FavoritesDatabase.columnSongId: songId,
      FavoritesDatabase.columnTitle: title,
      FavoritesDatabase.columnArtist: artist,
      FavoritesDatabase.columnAlbum: album,
      FavoritesDatabase.columnFilePath: filePath,
      FavoritesDatabase.columnDuration: durationMs,
      FavoritesDatabase.columnArtworkPath: artworkPath,
      FavoritesDatabase.columnTrackNumber: trackNumber,
      FavoritesDatabase.columnDateAdded: dateAdded,
    };

    if (includeId && id != null) {
      map[FavoritesDatabase.columnId] = id;
    }

    return map;
  }

  /// Crea un modelo desde una entidad Song del dominio
  ///
  /// Este método permite convertir una canción detectada por on_audio_query
  /// en un registro persistible en SQLite
  factory FavoriteSongModel.fromSongEntity(Song song, String userId) {
    return FavoriteSongModel(
      userId: userId,
      songId: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      filePath: song.filePath,
      durationMs: song.duration.inMilliseconds,
      artworkPath: song.artworkPath,
      trackNumber: song.trackNumber,
      dateAdded: song.dateAdded?.toIso8601String(),
    );
  }

  /// Convierte el modelo a una entidad Song del dominio
  ///
  /// Permite usar los favoritos como canciones normales en la aplicación
  Song toSongEntity() {
    return Song(
      id: songId,
      title: title,
      artist: artist,
      album: album,
      filePath: filePath,
      duration: Duration(milliseconds: durationMs),
      artworkPath: artworkPath,
      trackNumber: trackNumber,
      dateAdded: dateAdded != null ? DateTime.parse(dateAdded!) : null,
    );
  }

  /// Crea una copia del modelo con campos modificados
  ///
  /// Útil para actualizar favoritos sin mutar el objeto original
  FavoriteSongModel copyWith({
    int? id,
    String? userId,
    String? songId,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? durationMs,
    String? artworkPath,
    int? trackNumber,
    String? dateAdded,
    String? createdAt,
  }) {
    return FavoriteSongModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      artworkPath: artworkPath ?? this.artworkPath,
      trackNumber: trackNumber ?? this.trackNumber,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validación de datos antes de persistir
  ///
  /// Verifica que los campos obligatorios tengan valores válidos
  /// Returns: true si el modelo es válido, false en caso contrario
  bool isValid() {
    return userId.isNotEmpty &&
        songId.isNotEmpty &&
        title.isNotEmpty &&
        filePath.isNotEmpty &&
        durationMs >= 0;
  }

  /// Representación en string para debugging
  @override
  String toString() {
    return 'FavoriteSongModel(id: $id, userId: $userId, songId: $songId, '
        'title: $title, artist: $artist, filePath: $filePath)';
  }

  /// Compara dos modelos por igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FavoriteSongModel &&
        other.userId == userId &&
        other.songId == songId &&
        other.filePath == filePath;
  }

  /// Genera hash code para usar en colecciones
  @override
  int get hashCode => userId.hashCode ^ songId.hashCode ^ filePath.hashCode;
}

/// Extension methods para conversiones masivas
extension FavoriteSongModelListExtension on List<FavoriteSongModel> {
  /// Convierte una lista de modelos a entidades Song
  List<Song> toSongEntities() {
    return map((model) => model.toSongEntity()).toList();
  }

  /// Filtra modelos válidos
  List<FavoriteSongModel> filterValid() {
    return where((model) => model.isValid()).toList();
  }
}

/// Extension methods para conversiones desde Song
extension SongToFavoriteExtension on Song {
  /// Convierte una canción a modelo de favorito
  FavoriteSongModel toFavoriteModel(String userId) {
    return FavoriteSongModel.fromSongEntity(this, userId);
  }
}
