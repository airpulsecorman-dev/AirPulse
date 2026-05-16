# 🎵 Sistema de Favoritos - AirPulse

## 📋 Descripción General

Sistema profesional de gestión de canciones favoritas implementado con **Flutter + SQLite**, siguiendo los principios de **Clean Architecture** y las mejores prácticas de desarrollo empresarial.

### ✨ Características Principales

- ✅ **Persistencia local con SQLite** - Base de datos optimizada con índices
- ✅ **Sin duplicación de archivos** - Solo guarda metadata (paths, no archivos)
- ✅ **Validación automática** - Detecta y elimina favoritos con archivos eliminados
- ✅ **Caché inteligente** - Optimiza rendimiento reduciendo consultas a BD
- ✅ **Búsqueda en tiempo real** - Busca por título, artista o álbum
- ✅ **Arquitectura limpia** - Separación clara entre capas
- ✅ **Manejo robusto de errores** - Try-catch exhaustivo con mensajes claros
- ✅ **Componentes UI reutilizables** - FavoriteButton con animaciones
- ✅ **Operaciones optimistas** - UI reactiva sin esperar a la BD

---

## 🏗️ Arquitectura del Sistema

```bash
lib/
├── data/                           # Capa de Datos
│   ├── sources/
│   │   └── local/
│   │       └── favorites_database.dart      # ⚡ Servicio SQLite profesional
│   ├── models/
│   │   └── favorite_song_model.dart         # 📦 Modelo para SQLite
│   └── repositories/
│       └── favorites_repository_impl.dart   # 🔄 Implementación del repositorio
│
├── domain/                         # Capa de Dominio
│   ├── entities/
│   │   └── song.dart                        # 🎵 Entidad Song
│   ├── repositories/
│   │   └── favorites_repository.dart        # 📝 Contrato del repositorio
│   └── usecases/
│       └── favorites_usecases.dart          # 🎯 10 casos de uso
│
├── presentation/                   # Capa de Presentación
│   ├── providers/
│   │   └── favorites_provider.dart          # 🔔 State management
│   ├── components/
│   │   └── favorite_button.dart             # 💖 Botón de favorito
│   └── pages/
│       └── favorites_page.dart              # 📱 Página de favoritos
│
└── core/
    └── di/
        └── service_locator.dart             # 🔧 Inyección de dependencias
```

---

## 🗄️ Estructura de Base de Datos

### Tabla: `favorite_songs`

```sql
CREATE TABLE favorite_songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  file_path TEXT NOT NULL,            -- ⚠️ UNIQUE: Ruta del archivo MP3
  duration_ms INTEGER NOT NULL,
  artwork_path TEXT,
  track_number INTEGER DEFAULT 0,
  date_added TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, song_id) ON CONFLICT REPLACE
);

-- Índices para optimizar consultas
CREATE INDEX idx_user_id ON favorite_songs(user_id);
CREATE INDEX idx_song_id ON favorite_songs(song_id);
CREATE INDEX idx_file_path ON favorite_songs(file_path);
CREATE INDEX idx_created_at ON favorite_songs(created_at DESC);
```

### ⚙️ Optimizaciones SQLite

```dart
PRAGMA foreign_keys = ON;           // Integridad referencial
PRAGMA journal_mode = WAL;          // Write-Ahead Logging (concurrencia)
PRAGMA synchronous = NORMAL;        // Balance seguridad/rendimiento
PRAGMA cache_size = 10000;          // Cache de 10MB
PRAGMA temp_store = MEMORY;         // Tablas temporales en memoria
```

---

## 📚 Casos de Uso Disponibles

### 1️⃣ **GetFavoritesUseCase**

Obtiene todos los favoritos del usuario con validación automática.

```dart
final favorites = await GetFavoritesUseCase(repo).call(userId);
```

### 2️⃣ **AddFavoriteUseCase**

Agrega una canción a favoritos con validación de archivo.

```dart
await AddFavoriteUseCase(repo).call(userId, song);
```

### 3️⃣ **RemoveFavoriteUseCase**

Elimina una canción de favoritos.

```dart
await RemoveFavoriteUseCase(repo).call(userId, songId);
```

### 4️⃣ **IsFavoriteUseCase**

Verifica si una canción es favorita (consulta rápida).

```dart
final isFav = await IsFavoriteUseCase(repo).call(userId, songId);
```

### 5️⃣ **ToggleFavoriteUseCase**

Alterna el estado de favorito (add/remove en una operación).

```dart
final isNowFavorite = await ToggleFavoriteUseCase(repo).call(userId, song);
```

### 6️⃣ **CleanInvalidFavoritesUseCase**

Elimina favoritos con archivos inexistentes.

```dart
final deletedCount = await CleanInvalidFavoritesUseCase(repo).call(userId);
print('Se eliminaron $deletedCount favoritos inválidos');
```

### 7️⃣ **GetFavoritesCountUseCase**

Obtiene el número total de favoritos (optimizado con COUNT).

```dart
final count = await GetFavoritesCountUseCase(repo).call(userId);
```

### 8️⃣ **SearchFavoritesUseCase**

Busca favoritos por texto (título, artista, álbum).

```dart
final results = await SearchFavoritesUseCase(repo).call(userId, 'rock');
```

### 9️⃣ **ClearAllFavoritesUseCase**

Elimina todos los favoritos del usuario.

```dart
await ClearAllFavoritesUseCase(repo).call(userId);
```

### 🔟 **GetFavoritesStatisticsUseCase**

Obtiene estadísticas de la base de datos.

```dart
final stats = await GetFavoritesStatisticsUseCase(repo).call(userId);
print('Total favoritos: ${stats['totalFavorites']}');
print('Tamaño BD: ${stats['databaseSizeKB']} KB');
```

---

## 💻 Ejemplos de Uso

### 📱 Ejemplo 1: Uso en una Página de Biblioteca

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final songs = getSongsFromDevice(); // on_audio_query

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];

        return ListTile(
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: FavoriteButton(
            song: song,
            size: 24,
            onChanged: (isFavorite) {
              print('${song.title} ahora es favorito: $isFavorite');
            },
          ),
        );
      },
    );
  }
}
```

### 🎵 Ejemplo 2: Botón Flotante en Player

```dart
class PlayerPage extends StatelessWidget {
  final Song currentSong;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Artwork, título, controles...

          FavoriteFloatingButton(
            song: currentSong,
            onChanged: (isFavorite) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                  isFavorite ? 'Agregado a favoritos ❤️' : 'Eliminado de favoritos'
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 🔍 Ejemplo 3: Búsqueda en Favoritos

```dart
class FavoritesSearchPage extends StatefulWidget {
  @override
  State<FavoritesSearchPage> createState() => _FavoritesSearchPageState();
}

class _FavoritesSearchPageState extends State<FavoritesSearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    final userId = context.read<AuthProvider>().currentUser?.id;

    if (userId != null) {
      context.read<FavoritesProvider>().searchFavorites(userId, query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final results = favoritesProvider.searchQuery.isEmpty
        ? favoritesProvider.favorites
        : favoritesProvider.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar en favoritos...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final song = results[index];
          return ListTile(
            title: Text(song.title),
            subtitle: Text('${song.artist} · ${song.album}'),
            trailing: FavoriteCompactButton(song: song),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

### 🧹 Ejemplo 4: Limpieza Automática al Inicio

```dart
// En main.dart o splash screen
Future<void> initApp() async {
  final userId = getCurrentUserId();
  final favoritesProvider = sl<FavoritesProvider>();

  // Carga favoritos con limpieza automática
  await favoritesProvider.loadFavorites(userId, cleanInvalid: true);

  if (favoritesProvider.lastCleanedCount > 0) {
    print('Se eliminaron ${favoritesProvider.lastCleanedCount} favoritos rotos');
  }
}
```

### 📊 Ejemplo 5: Mostrar Estadísticas

```dart
class FavoritesStatsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<FavoritesProvider>().getStatistics(userId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final stats = snapshot.data!;

        return AlertDialog(
          title: Text('Estadísticas de Favoritos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${stats['totalFavorites']} canciones'),
              Text('Tamaño BD: ${stats['databaseSizeKB']} KB'),
              Text('Versión: ${stats['databaseVersion']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 🎨 Variantes del FavoriteButton

### 1. Botón Estándar

```dart
FavoriteButton(
  song: song,
  size: 24,
  onChanged: (isFavorite) => print(isFavorite),
)
```

### 2. Botón con Fondo

```dart
FavoriteButton(
  song: song,
  size: 28,
  showBackground: true,
  backgroundColor: Colors.black.withOpacity(0.3),
  padding: EdgeInsets.all(12),
)
```

### 3. Botón Compacto (para listas)

```dart
FavoriteCompactButton(song: song)
```

### 4. Botón Flotante (para player)

```dart
FavoriteFloatingButton(
  song: song,
  onChanged: (isFavorite) {
    // Feedback personalizado
  },
)
```

### 5. Botón Estilo IconButton

```dart
FavoriteIconButton(
  song: song,
  favoriteColor: Colors.red,
  normalColor: Colors.grey,
)
```

---

## 🔧 Configuración Inicial

### 1. Registrar Dependencias en `main.dart`

```dart
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa dependencias (incluye favoritos)
  await setupDependencies(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(sl<FavoritesRepository>()),
        ),
        // ... otros providers
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Cargar Favoritos al Iniciar Sesión

```dart
// En AuthProvider o LoginPage
Future<void> onLoginSuccess(User user) async {
  final favoritesProvider = context.read<FavoritesProvider>();

  // Carga favoritos con limpieza automática
  await favoritesProvider.loadFavorites(user.id, cleanInvalid: true);

  Navigator.pushReplacementNamed(context, '/home');
}
```

### 3. Limpiar al Cerrar Sesión

```dart
Future<void> onLogout() async {
  final favoritesProvider = context.read<FavoritesProvider>();

  // Limpia el estado del provider
  favoritesProvider.clear();

  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## ⚡ Optimizaciones y Mejores Prácticas

### ✅ DO: Buenas Prácticas

```dart
// ✅ Usar caché del provider para verificaciones rápidas
final isFavorite = favoritesProvider.isFavorite(songId);

// ✅ Limpieza automática periódica
Timer.periodic(Duration(hours: 24), (_) {
  favoritesProvider.cleanInvalidFavorites(userId);
});

// ✅ Operaciones optimistas para UI reactiva
await favoritesProvider.toggleFavorite(userId, song);

// ✅ Búsqueda con debounce
_debouncer.run(() {
  favoritesProvider.searchFavorites(userId, query);
});
```

### ❌ DON'T: Evitar

```dart
// ❌ NO consultar el repositorio directamente desde la UI
final isFavorite = await repo.isFavorite(userId, songId);

// ❌ NO guardar archivos MP3 en SQLite
await db.insert({'mp3_data': File(path).readAsBytesSync()});

// ❌ NO hacer consultas sin índices
SELECT * FROM favorite_songs WHERE title LIKE '%query%';

// ❌ NO olvidar validar archivos
await addFavorite(song); // Sin verificar si el archivo existe
```

---

## 🧪 Testing

### Unit Test: Use Case

```dart
test('ToggleFavoriteUseCase agrega canción no favorita', () async {
  // Arrange
  final mockRepo = MockFavoritesRepository();
  final useCase = ToggleFavoriteUseCase(mockRepo);
  final song = Song(id: '1', title: 'Test', ...);

  when(mockRepo.isFavorite('user1', '1')).thenAnswer((_) async => false);

  // Act
  final result = await useCase.call('user1', song);

  // Assert
  expect(result, true);
  verify(mockRepo.addFavorite('user1', song)).called(1);
});
```

### Widget Test: FavoriteButton

```dart
testWidgets('FavoriteButton alterna estado al presionar', (tester) async {
  // Arrange
  final song = Song(id: '1', title: 'Test', ...);
  bool? changedValue;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FavoriteButton(
          song: song,
          onChanged: (value) => changedValue = value,
        ),
      ),
    ),
  );

  // Act
  await tester.tap(find.byType(FavoriteButton));
  await tester.pumpAndSettle();

  // Assert
  expect(changedValue, isNotNull);
});
```

---

## 📝 Migración desde SharedPreferences

Si ya tienes favoritos en SharedPreferences, puedes migrarlos:

```dart
Future<void> migrateFavoritesFromPrefs(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'airpulse_favorites_$userId';
  final raw = prefs.getString(key);

  if (raw != null) {
    final list = jsonDecode(raw) as List;
    final songs = list.map((e) => SongModel.fromJson(e)).toList();

    final favoritesProvider = sl<FavoritesProvider>();

    for (final song in songs) {
      try {
        await favoritesProvider.addFavorite(userId, song);
      } catch (e) {
        print('Error migrando ${song.title}: $e');
      }
    }

    // Limpia SharedPreferences después de migrar
    await prefs.remove(key);
    print('Migración completada: ${songs.length} canciones');
  }
}
```

---

## 🐛 Troubleshooting

### Problema: "DatabaseException: unable to open database"

**Solución:** Verifica permisos de escritura en el directorio de documentos.

```dart
final dir = await getApplicationDocumentsDirectory();
print('BD Path: ${dir.path}');
```

### Problema: Favoritos no se cargan después de reiniciar

**Solución:** Asegúrate de llamar `loadFavorites()` en `initState()`.

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<FavoritesProvider>().loadFavorites(userId);
  });
}
```

### Problema: Archivos eliminados siguen en favoritos

**Solución:** Habilita limpieza automática.

```dart
await favoritesProvider.loadFavorites(userId, cleanInvalid: true);
```

---

## 📦 Dependencias Requeridas

```yaml
dependencies:
  sqflite: ^2.4.1 # SQLite
  path_provider: ^2.1.5 # Rutas del sistema
  provider: ^6.1.2 # State management
  equatable: ^2.0.7 # Comparación de objetos
  get_it: ^8.0.3 # Inyección de dependencias
```

---

## 🚀 Roadmap Futuro

- [ ] Sincronización en la nube (Firebase/Supabase)
- [ ] Exportar/importar favoritos (JSON/CSV)
- [ ] Playlists inteligentes basadas en favoritos
- [ ] Estadísticas avanzadas (canciones más escuchadas)
- [ ] Soporte para múltiples perfiles de usuario
- [ ] Respaldo automático de favoritos

---

## 📄 Licencia

Sistema de Favoritos - AirPulse  
© 2026 - Todos los derechos reservados

---

## 🙏 Créditos

- Diseño arquitectónico: Clean Architecture (Robert C. Martin)
- Patrón Repository: Domain-Driven Design
- SQLite optimization: [SQLite Performance Tips](https://www.sqlite.org/optoverview.html)
- Flutter best practices: [flutter.dev](https://flutter.dev)

---

**¿Preguntas o sugerencias?**  
📧 Contáctanos o abre un issue en GitHub
