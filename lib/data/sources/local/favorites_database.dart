import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Servicio profesional de base de datos SQLite para favoritos
///
/// Gestiona la persistencia local de canciones favoritas con:
/// - Tabla optimizada con índices
/// - Validación de integridad de archivos
/// - Migraciones versionadas
/// - Manejo robusto de errores
/// - Limpieza automática de favoritos rotos
class FavoritesDatabase {
  static const String _databaseName = 'airpulse_favorites.db';
  static const int _databaseVersion = 1;

  // Tabla de favoritos
  static const String tableFavorites = 'favorite_songs';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnSongId = 'song_id';
  static const String columnTitle = 'title';
  static const String columnArtist = 'artist';
  static const String columnAlbum = 'album';
  static const String columnFilePath = 'file_path';
  static const String columnDuration = 'duration_ms';
  static const String columnArtworkPath = 'artwork_path';
  static const String columnTrackNumber = 'track_number';
  static const String columnDateAdded = 'date_added';
  static const String columnCreatedAt = 'created_at';

  static Database? _database;

  /// Singleton para garantizar una única instancia de la base de datos
  FavoritesDatabase._privateConstructor();
  static final FavoritesDatabase instance =
      FavoritesDatabase._privateConstructor();

  /// Obtiene la instancia de la base de datos (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  ///
  /// Crea el archivo de base de datos en el directorio de bases de datos
  /// y ejecuta las migraciones necesarias
  Future<Database> _initDatabase() async {
    try {
      // Usar getDatabasesPath() en lugar de getApplicationDocumentsDirectory()
      // Este es el directorio recomendado para bases de datos SQLite
      final String databasesPath = await getDatabasesPath();
      final String path = join(databasesPath, _databaseName);

      // Asegurar que el directorio existe
      final Directory directory = Directory(databasesPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw DatabaseException('Error al inicializar base de datos: $e');
    }
  }

  /// Configura la base de datos antes de abrirla
  ///
  /// Habilita claves foráneas y optimizaciones de rendimiento
  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      print('Error configurando foreign_keys: $e');
    }

    try {
      // Write-Ahead Logging para mejor concurrencia
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (e) {
      print('Error configurando journal_mode: $e');
    }

    try {
      // Balance entre seguridad y rendimiento
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (e) {
      print('Error configurando synchronous: $e');
    }

    try {
      // Cache de 10MB
      await db.execute('PRAGMA cache_size = 10000');
    } catch (e) {
      print('Error configurando cache_size: $e');
    }

    try {
      // Tablas temporales en memoria
      await db.execute('PRAGMA temp_store = MEMORY');
    } catch (e) {
      print('Error configurando temp_store: $e');
    }
  }

  /// Crea la estructura inicial de la base de datos
  ///
  /// Define la tabla de favoritos con:
  /// - Clave primaria auto-incremental
  /// - Índices para búsquedas rápidas
  /// - Restricción UNIQUE para evitar duplicados por usuario+canción
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFavorites (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId TEXT NOT NULL,
        $columnSongId TEXT NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnArtist TEXT NOT NULL,
        $columnAlbum TEXT NOT NULL,
        $columnFilePath TEXT NOT NULL,
        $columnDuration INTEGER NOT NULL,
        $columnArtworkPath TEXT,
        $columnTrackNumber INTEGER DEFAULT 0,
        $columnDateAdded TEXT,
        $columnCreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE($columnUserId, $columnSongId) ON CONFLICT REPLACE
      )
    ''');

    // Índices para optimizar consultas frecuentes
    await db.execute('''
      CREATE INDEX idx_user_id ON $tableFavorites($columnUserId)
    ''');

    await db.execute('''
      CREATE INDEX idx_song_id ON $tableFavorites($columnSongId)
    ''');

    await db.execute('''
      CREATE INDEX idx_file_path ON $tableFavorites($columnFilePath)
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at ON $tableFavorites($columnCreatedAt DESC)
    ''');
  }

  /// Maneja actualizaciones de esquema de base de datos
  ///
  /// Permite migraciones versionadas para mantener compatibilidad
  /// al actualizar la estructura de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejemplo de migración para versiones futuras:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableFavorites ADD COLUMN new_field TEXT');
    // }

    // Por ahora no hay migraciones
  }

  /// Inserta o actualiza un favorito
  ///
  /// Usa CONFLICT_REPLACE para evitar duplicados
  /// Returns: ID del registro insertado/actualizado
  Future<int> insertFavorite(Map<String, dynamic> favorite) async {
    try {
      final db = await database;
      return await db.insert(
        tableFavorites,
        favorite,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Error al insertar favorito: $e');
    }
  }

  /// Obtiene todos los favoritos de un usuario
  ///
  /// Ordena por fecha de creación descendente (más recientes primero)
  /// Returns: Lista de mapas con los datos de los favoritos
  Future<List<Map<String, dynamic>>> getFavoritesByUserId(String userId) async {
    try {
      final db = await database;
      return await db.query(
        tableFavorites,
        where: '$columnUserId = ?',
        whereArgs: [userId],
        orderBy: '$columnCreatedAt DESC',
      );
    } catch (e) {
      throw DatabaseException('Error al obtener favoritos: $e');
    }
  }

  /// Verifica si una canción es favorita para un usuario
  ///
  /// Returns: true si la canción está en favoritos, false en caso contrario
  Future<bool> isFavorite(String userId, String songId) async {
    try {
      final db = await database;
      final result = await db.query(
        tableFavorites,
        where: '$columnUserId = ? AND $columnSongId = ?',
        whereArgs: [userId, songId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw DatabaseException('Error al verificar favorito: $e');
    }
  }

  /// Elimina un favorito específico
  ///
  /// Returns: Número de filas eliminadas (0 o 1)
  Future<int> deleteFavorite(String userId, String songId) async {
    try {
      final db = await database;
      return await db.delete(
        tableFavorites,
        where: '$columnUserId = ? AND $columnSongId = ?',
        whereArgs: [userId, songId],
      );
    } catch (e) {
      throw DatabaseException('Error al eliminar favorito: $e');
    }
  }

  /// Elimina todos los favoritos de un usuario
  ///
  /// Útil para cerrar sesión o limpiar datos
  /// Returns: Número de filas eliminadas
  Future<int> deleteAllFavorites(String userId) async {
    try {
      final db = await database;
      return await db.delete(
        tableFavorites,
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw DatabaseException('Error al eliminar todos los favoritos: $e');
    }
  }

  /// Valida y limpia favoritos con archivos inexistentes
  ///
  /// Recorre todos los favoritos de un usuario y elimina aquellos
  /// cuyo archivo de audio ya no existe en el sistema de archivos
  ///
  /// Returns: Número de favoritos eliminados por archivos faltantes
  Future<int> cleanInvalidFavorites(String userId) async {
    try {
      final favorites = await getFavoritesByUserId(userId);
      int deletedCount = 0;

      for (final favorite in favorites) {
        final filePath = favorite[columnFilePath] as String;
        final file = File(filePath);

        // Si el archivo no existe, eliminar de favoritos
        if (!await file.exists()) {
          final songId = favorite[columnSongId] as String;
          await deleteFavorite(userId, songId);
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (e) {
      throw DatabaseException('Error al limpiar favoritos inválidos: $e');
    }
  }

  /// Valida si un archivo específico existe
  ///
  /// Útil para verificar antes de agregar a favoritos
  /// Returns: true si el archivo existe, false en caso contrario
  Future<bool> validateFilePath(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el número total de favoritos de un usuario
  ///
  /// Optimizado con COUNT(*) en lugar de cargar todos los registros
  /// Returns: Cantidad de favoritos
  Future<int> getFavoritesCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableFavorites WHERE $columnUserId = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Error al contar favoritos: $e');
    }
  }

  /// Busca favoritos por texto (título, artista o álbum)
  ///
  /// Útil para implementar búsqueda en la página de favoritos
  /// Returns: Lista de favoritos que coinciden con la búsqueda
  Future<List<Map<String, dynamic>>> searchFavorites(
    String userId,
    String query,
  ) async {
    try {
      final db = await database;
      final searchTerm = '%${query.toLowerCase()}%';

      return await db.query(
        tableFavorites,
        where:
            '''
          $columnUserId = ? AND (
            LOWER($columnTitle) LIKE ? OR 
            LOWER($columnArtist) LIKE ? OR 
            LOWER($columnAlbum) LIKE ?
          )
        ''',
        whereArgs: [userId, searchTerm, searchTerm, searchTerm],
        orderBy: '$columnCreatedAt DESC',
      );
    } catch (e) {
      throw DatabaseException('Error al buscar favoritos: $e');
    }
  }

  /// Cierra la base de datos
  ///
  /// Debe llamarse cuando la aplicación se cierra o en dispose()
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Elimina completamente la base de datos
  ///
  /// PELIGROSO: Solo para debugging o reset completo
  Future<void> deleteDatabase() async {
    try {
      final String databasesPath = await getDatabasesPath();
      final String path = join(databasesPath, _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
    } catch (e) {
      throw DatabaseException('Error al eliminar base de datos: $e');
    }
  }

  /// Obtiene estadísticas de la base de datos
  ///
  /// Útil para debugging y monitoreo
  /// Returns: Mapa con información sobre la base de datos
  Future<Map<String, dynamic>> getDatabaseStats(String userId) async {
    try {
      final db = await database;

      final totalFavorites = await getFavoritesCount(userId);

      final dbPath = db.path;
      final dbFile = File(dbPath);
      final dbSize = await dbFile.length();

      return {
        'totalFavorites': totalFavorites,
        'databasePath': dbPath,
        'databaseSizeBytes': dbSize,
        'databaseSizeKB': (dbSize / 1024).toStringAsFixed(2),
        'databaseVersion': _databaseVersion,
      };
    } catch (e) {
      throw DatabaseException('Error al obtener estadísticas: $e');
    }
  }
}

/// Excepción personalizada para errores de base de datos
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
