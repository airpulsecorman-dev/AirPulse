# 🚀 Sistema de Favoritos - Quick Start

## ⚡ Integración en 5 Pasos

### 1️⃣ Las dependencias ya están registradas

El service locator ya inicializa automáticamente:

- ✅ FavoritesDatabase (SQLite)
- ✅ FavoritesRepository
- ✅ Todos los use cases
- ✅ FavoritesProvider

### 2️⃣ Agregar Provider en main.dart

```dart
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';

void main() async {
  // ... inicialización existente
  await setupDependencies(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        // Agrega FavoritesProvider
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(sl<FavoritesRepository>()),
        ),

        // ... tus otros providers existentes
        // ChangeNotifierProvider(create: (_) => AudioProvider(...)),
        // ChangeNotifierProvider(create: (_) => AuthProvider(...)),
      ],
      child: MyApp(),
    ),
  );
}
```

### 3️⃣ Cargar favoritos al iniciar sesión

```dart
// En tu AuthProvider después de login exitoso
Future<void> loginUser(String email, String password) async {
  // ... lógica de autenticación existente

  // Cargar favoritos del usuario
  final favoritesProvider = sl<FavoritesProvider>();
  await favoritesProvider.loadFavorites(currentUser!.id, cleanInvalid: true);
}
```

### 4️⃣ Usar FavoriteButton en cualquier lugar

```dart
import 'package:airpulse/presentation/components/favorite_button.dart';

// En ListTile de canciones
ListTile(
  title: Text(song.title),
  trailing: FavoriteButton(song: song, size: 24),
)

// En Player
FavoriteFloatingButton(song: currentSong)

// En listas compactas
FavoriteCompactButton(song: song)
```

### 5️⃣ Página de favoritos ya está actualizada

La página `favorites_page.dart` ya usa el nuevo sistema automáticamente.

---

## 📂 Archivos Creados/Modificados

### ✨ Archivos Nuevos

1. `lib/data/sources/local/favorites_database.dart` - Servicio SQLite
2. `lib/data/models/favorite_song_model.dart` - Modelo para BD
3. `lib/presentation/components/favorite_button.dart` - Componente UI
4. `FAVORITES_SYSTEM_GUIDE.md` - Documentación completa

### 🔧 Archivos Modificados

1. `lib/data/repositories/favorites_repository_impl.dart` - Ahora usa SQLite
2. `lib/domain/usecases/favorites_usecases.dart` - 10 use cases profesionales
3. `lib/presentation/providers/favorites_provider.dart` - Provider optimizado
4. `lib/presentation/pages/favorites_page.dart` - Usa FavoriteButton
5. `lib/core/di/service_locator.dart` - Registra dependencias

---

## 🎯 Usar FavoriteButton en tus Páginas

### En Library Page (lista de todas las canciones)

```dart
// lib/presentation/pages/library_page.dart
import '../components/favorite_button.dart';

Widget _buildSongTile(Song song) {
  return ListTile(
    leading: QueryArtworkWidget(...),
    title: Text(song.title),
    subtitle: Text(song.artist),
    trailing: FavoriteButton(
      song: song,
      size: 24,
      onChanged: (isFavorite) {
        // Opcional: mostrar SnackBar
      },
    ),
    onTap: () => playService.play(song),
  );
}
```

### En Player Page (canción actual)

```dart
// lib/presentation/pages/player_page.dart
import '../components/favorite_button.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Artwork grande
        _buildArtwork(),

        // Título y artista
        _buildSongInfo(),

        // Botón de favorito flotante
        FavoriteFloatingButton(
          song: currentSong,
          onChanged: (isFavorite) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isFavorite
                  ? '💖 Agregado a favoritos'
                  : 'Eliminado de favoritos'
                ),
              ),
            );
          },
        ),

        // Controles de reproducción
        _buildControls(),
      ],
    ),
  );
}
```

### En Album Detail Page

```dart
// lib/presentation/pages/album_detail_page.dart
import '../components/favorite_button.dart';

Widget _buildSongsList() {
  return ListView.builder(
    itemCount: albumSongs.length,
    itemBuilder: (context, index) {
      final song = albumSongs[index];

      return ListTile(
        leading: Text('${index + 1}', style: TextStyle(color: Colors.grey)),
        title: Text(song.title),
        subtitle: Text(formatDuration(song.duration)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón compacto para listas
            FavoriteCompactButton(song: song),

            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () => _showSongOptions(song),
            ),
          ],
        ),
        onTap: () => audioService.play(song, queue: albumSongs),
      );
    },
  );
}
```

---

## 🔍 Búsqueda en Favoritos

Ya implementada en `FavoritesProvider`:

```dart
// En cualquier página
final favoritesProvider = context.read<FavoritesProvider>();
final userId = context.read<AuthProvider>().currentUser?.id;

// Buscar
await favoritesProvider.searchFavorites(userId!, 'rock');

// Obtener resultados
final results = favoritesProvider.searchResults;

// Limpiar búsqueda
favoritesProvider.clearSearch();
```

---

## 🧹 Limpieza Automática

### Opción 1: Al cargar favoritos (recomendado)

```dart
await favoritesProvider.loadFavorites(userId, cleanInvalid: true);
```

### Opción 2: Manualmente cuando quieras

```dart
final deletedCount = await favoritesProvider.cleanInvalidFavorites(userId);
print('Se eliminaron $deletedCount favoritos con archivos faltantes');
```

### Opción 3: Automático cada 24h

```dart
// En main.dart o servicio de background
Timer.periodic(Duration(hours: 24), (_) async {
  final userId = getCurrentUserId();
  if (userId != null) {
    await favoritesProvider.cleanInvalidFavorites(userId);
  }
});
```

---

## 📊 Verificar si una canción es favorita

```dart
// Método 1: Desde el provider (más rápido, usa caché)
final isFavorite = favoritesProvider.isFavorite(songId);

// Método 2: Directamente (si no tienes acceso al provider)
final favoritesProvider = context.watch<FavoritesProvider>();
final isFavorite = favoritesProvider.isFavorite(song.id);
```

---

## 🎨 Customizar Colores del FavoriteButton

```dart
FavoriteButton(
  song: song,
  size: 28,
  favoriteColor: Color(0xFFE91E63),  // Rosa personalizado
  normalColor: Colors.grey[400],      // Gris personalizado
  showBackground: true,
  backgroundColor: Colors.black.withOpacity(0.2),
  padding: EdgeInsets.all(10),
)
```

---

## 📱 Ejemplo de Integración Completa

```dart
// lib/presentation/widgets/song_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/favorite_button.dart';
import '../../domain/entities/song.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongCard({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            song.artworkPath ?? 'assets/default_artwork.png',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${song.artist} · ${song.album}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12),
        ),
        trailing: FavoriteButton(
          song: song,
          size: 24,
          onChanged: (isFavorite) {
            final message = isFavorite
              ? 'Agregado a favoritos 💖'
              : 'Eliminado de favoritos';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 🔒 Cerrar Sesión

```dart
Future<void> logout() async {
  // Limpiar estado de favoritos
  context.read<FavoritesProvider>().clear();

  // Limpiar otros providers
  context.read<AudioProvider>().clear();

  // Navegar a login
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## ⚙️ Base de Datos en Dispositivo

La base de datos se guarda automáticamente en:

### Android

```bash
/data/data/com.tuapp.airpulse/documents/airpulse_favorites.db
```

### iOS

```bash
/var/mobile/Containers/Data/Application/[UUID]/Documents/airpulse_favorites.db
```

### Tamaño aproximado

- Solo metadata: **~1 KB por canción favorita**
- 1000 canciones favoritas ≈ **1 MB**
- Sin archivos MP3 guardados ✅

---

## 🐛 Debugging

### Ver base de datos en desarrollo

```dart
// En debug mode
final stats = await favoritesProvider.getStatistics(userId);
print('📊 Estadísticas de Favoritos:');
print('Total: ${stats['totalFavorites']} canciones');
print('Tamaño: ${stats['databaseSizeKB']} KB');
print('Ruta: ${stats['databasePath']}');
```

### Resetear base de datos (solo debug)

```dart
// ⚠️ PELIGROSO: Elimina toda la base de datos
final db = FavoritesDatabase.instance;
await db.deleteDatabase();
print('Base de datos eliminada');
```

---

## ✅ Checklist de Integración

- [ ] Agregado FavoritesProvider en MultiProvider
- [ ] Llamado loadFavorites() después de login
- [ ] Importado favorite_button.dart donde lo necesites
- [ ] Reemplazado botones de favorito antiguos con FavoriteButton
- [ ] Limpieza automática habilitada (cleanInvalid: true)
- [ ] Probado agregar/eliminar favoritos
- [ ] Probado búsqueda en favoritos
- [ ] Probado con archivos eliminados del dispositivo
- [ ] Verificado que funcione sin conexión a internet

---

## 🎉 Listo

Tu sistema de favoritos profesional está completamente configurado.

**Características que tienes ahora:**

- ✅ Persistencia local con SQLite optimizado
- ✅ Validación automática de archivos
- ✅ Componentes UI reutilizables con animaciones
- ✅ Búsqueda en tiempo real
- ✅ Arquitectura limpia y escalable
- ✅ Manejo robusto de errores
- ✅ Cache inteligente para rendimiento
- ✅ 10 casos de uso profesionales

**Siguiente paso recomendado:**
Lee el archivo `FAVORITES_SYSTEM_GUIDE.md` para documentación completa con ejemplos avanzados.

---

¿Dudas? Revisa la documentación completa o abre un issue. 🚀
