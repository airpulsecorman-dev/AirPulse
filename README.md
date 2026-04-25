# AirPulse

**AirPulse** es una aplicación de reproductor de música multiplataforma construida con Flutter. Permite reproducir la biblioteca de audio local del dispositivo (Android/iOS) y, al mismo tiempo, levantar un servidor HTTP/WebSocket embebido para que cualquier navegador en la misma red WiFi pueda conectarse, ver la biblioteca y controlar la reproducción de forma remota. La conexión se facilita mediante un código QR generado automáticamente.

---

## ¿De qué va el proyecto?

AirPulse es esencialmente un reproductor de música que funciona en dos modos:

1. **Modo local (móvil/desktop):** Accede a las canciones del dispositivo, las muestra organizadas por canciones, álbumes y artistas, permite reproducirlas, crear playlists, marcar favoritos y controlar la reproducción (play, pausa, siguiente, anterior, shuffle, repeat, volumen).

2. **Modo servidor (WiFi):** El móvil levanta un servidor HTTP en el puerto `8765`. Cualquier dispositivo en la misma red WiFi puede escanear el QR generado, acceder a la web app alojada en GitHub Pages (`https://18-anth.github.io/AirPulseWeb`), ver la biblioteca de música del móvil y reproducirla directamente en el navegador. La comunicación en tiempo real se realiza via WebSocket.

---

## Estructura de la carpeta `lib/`

La carpeta `lib/` sigue los principios de **Clean Architecture**, dividida en cinco capas claramente separadas:

```bash
lib/
├── main.dart                  # Punto de entrada
├── app/                       # Configuración raíz de la app
├── core/                      # Utilidades, constantes e inyección de dependencias
├── domain/                    # Entidades, repositorios (interfaces) y casos de uso
├── data/                      # Modelos, fuentes de datos e implementaciones de repositorios
├── services/                  # Servicios de orquestación (fachada)
└── presentation/              # UI: páginas, providers, componentes y hooks
```

---

## `main.dart`

Punto de entrada de la aplicación. Llama a `WidgetsFlutterBinding.ensureInitialized()`, configura el contenedor de inyección de dependencias (`setupDependencies()`) e inicia `AirPulseApp`.

---

## `app/`

Contiene el widget raíz `AirPulseApp` y la puerta de autenticación `_AuthGate`.

- **`AirPulseApp`**: Configura `MultiProvider` con todos los providers (Audio, Library, Auth, Favorites, Server), el tema Material 3 (modo oscuro por defecto, color primario `#6750A4`) y las rutas nombradas (`/`, `/player`, `/server`, `/login`, `/register`, `/favorites`).
- **`_AuthGate`**: Decide la pantalla inicial según el estado de autenticación. En web siempre muestra `LoginPage`; en móvil navega a `LibraryPage` si el usuario está autenticado.

---

## `core/`

Módulo transversal con utilidades compartidas por todas las capas.

| Archivo                        | Descripción                                                                                                                             |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| `constants/app_constants.dart` | Constantes globales: nombre de la app, versión, puerto del servidor (`8765`), URL de la web app, timeouts.                              |
| `di/service_locator.dart`      | Inyección de dependencias con **GetIt**. Registra como singletons: `AudioService`, `LibraryService`, `LocalServerService`, `QRService`. |
| `utils/duration_utils.dart`    | `formatDuration()` (formatea duración como `mm:ss`) y `playbackProgress()` (calcula progreso normalizado 0.0–1.0).                      |
| `utils/file_utils.dart`        | `isSupportedAudio()` (verifica extensiones mp3, flac, aac, ogg, wav, m4a, opus) y `readableFileSize()` (tamaño legible en B/KB/MB).     |
| `utils/network_utils.dart`     | `hasWifiConnection()`, `buildStreamUrl()` y `buildWebSocketUrl()` para construir URLs del servidor local.                               |

---

## `domain/`

Capa de dominio pura, sin dependencias externas. Define las reglas de negocio.

### Entidades (`domain/entities/`)

| Entidad         | Propiedades principales                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------ |
| `Song`          | `id`, `title`, `artist`, `album`, `filePath`, `duration`, `artworkPath`, `trackNumber`, `dateAdded`                |
| `Album`         | `id`, `title`, `artist`, `artworkPath`, `year`, `songs[]`                                                          |
| `Artist`        | `id`, `name`, `artworkPath`, `songs[]`                                                                             |
| `Playlist`      | `id`, `name`, `songs[]`, `createdAt`, `artworkPath`                                                                |
| `User`          | `id`, `username`, `email`, `avatarPath`, `createdAt`                                                               |
| `ServerSession` | `sessionId`, `localIp`, `port`, `status` (enum: stopped/starting/running/error), `qrPayload`, `connectedClients[]` |

### Repositorios — interfaces (`domain/repositories/`)

| Repositorio           | Responsabilidad                                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `AuthRepository`      | `register()`, `login()`, `logout()`, `isLoggedIn()`, `getCurrentUser()`                                                  |
| `LibraryRepository`   | `getAllSongs/Albums/Artists/Playlists()`, `searchSongs()`, `createPlaylist()`, `addSongToPlaylist()`, `deletePlaylist()` |
| `PlayerRepository`    | `play()`, `pause()`, `resume()`, `seek()`, `setVolume()`, `setQueue()`, `setRepeatMode()`, streams de estado             |
| `FavoritesRepository` | `getFavorites()`, `addFavorite()`, `removeFavorite()`, `isFavorite()`                                                    |
| `ServerRepository`    | `startServer()`, `stopServer()`, `getActiveSession()`, `broadcastPlayerState()`, streams de clientes                     |

### Casos de uso (`domain/usecases/`)

Encapsulan una única operación de negocio cada uno. Ejemplos: `LoginUseCase`, `GetLibraryUseCase`, `PlaySongUseCase`, `AddFavoriteUseCase`, `StartServerUseCase`.

---

## `data/`

Implementa las interfaces del dominio y gestiona el acceso real a los datos.

### Modelos (`data/models/`)

`SongModel`, `AlbumModel`, `PlaylistModel`, `UserModel`, `ServerSessionModel`. Cada uno extiende su entidad de dominio y añade `fromJson()`, `toJson()` y `fromEntity()`.

### Fuentes de datos locales (`data/sources/local/`)

- **`LibraryLocalSource`**: Usa el plugin `on_audio_query` para leer la biblioteca de audio del dispositivo. Solicita permisos de almacenamiento/audio, filtra archivos no musicales (WhatsApp, etc.) y mapea los resultados a entidades `Song`.
- **`AudioLocalSource`**: Controla el reproductor `just_audio`. Expone métodos `playSong()`, `setQueue()`, `pause()`, `resume()`, `seek()`, `setVolume()` y streams de estado (`isPlayingStream`, `positionStream`, `volumeStream`, `currentIndexStream`).

### Fuentes de datos remotas (`data/sources/remote/`)

- **`WebSocketSource`**: Gestiona el mapa de clientes WebSocket conectados. Permite `broadcast()` (a todos) y `sendToClient()` (a uno), y expone un stream de comandos recibidos.

### Implementaciones de repositorios (`data/repositories/`)

| Implementación            | Almacenamiento                                                   |
| ------------------------- | ---------------------------------------------------------------- |
| `AuthRepositoryImpl`      | `SharedPreferences` (usuarios y sesión activa)                   |
| `LibraryRepositoryImpl`   | `LibraryLocalSource` + playlists en memoria                      |
| `PlayerRepositoryImpl`    | `AudioLocalSource`                                               |
| `FavoritesRepositoryImpl` | `SharedPreferences` (por usuario: `airpulse_favorites_{userId}`) |

---

## `services/`

Capa de orquestación que actúa como fachada entre la presentación y el dominio/data.

### `AudioService`

Coordina la reproducción de audio. Mantiene el estado de `_currentSong`, `_queue`, `_currentIndex`, `_repeatMode` y `_shuffleEnabled`. Expone streams para que los providers de UI se suscriban. Serializa el estado del reproductor (`toJsonState()`) para broadcast via WebSocket.

### `LibraryService`

Delega a `LibraryRepositoryImpl`. Gestiona solicitud de permisos, carga de canciones/álbumes/artistas/playlists y búsqueda.

### `LocalServerService`

**Componente central del modo servidor.** Levanta un servidor HTTP con **Shelf** en el puerto `8765` y expone las siguientes rutas:

| Ruta                 | Método | Descripción                                        |
| -------------------- | ------ | -------------------------------------------------- |
| `/`                  | GET    | Página HTML completa con reproductor web embebido  |
| `/health`            | GET    | Health check (`{"status": "ok"}`)                  |
| `/songs`             | GET    | JSON con lista de todas las canciones              |
| `/songs/<id>/stream` | GET    | Stream del archivo de audio                        |
| `/state`             | GET    | Estado actual del reproductor                      |
| `/ws`                | GET    | Conexión WebSocket para comunicación bidireccional |

Genera automáticamente la IP local, construye la URL y genera el payload QR. Añade middleware CORS para permitir conexiones desde el navegador.

### `QRService`

Genera widgets QR (`qr_flutter`) con el payload `{"type": "airpulse_connect", "url": ..., "sessionId": ..., "version": "1"}` y parsea QRs escaneados.

---

## `presentation/`

Capa de interfaz de usuario.

### Providers (`presentation/providers/`)

State management con `ChangeNotifier` + `Provider`:

| Provider            | Estado gestionado                                                                        |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `AudioProvider`     | Canción actual, isPlaying, posición, volumen, repeatMode, shuffle, cola                  |
| `AuthProvider`      | Estado de autenticación (unknown/authenticated/unauthenticated), usuario actual, errores |
| `LibraryProvider`   | Canciones, álbumes, artistas, playlists, búsqueda, permisos                              |
| `ServerProvider`    | Sesión del servidor, clientes conectados, estado de inicio                               |
| `FavoritesProvider` | Lista de canciones favoritas del usuario                                                 |

### Hooks personalizados (`presentation/hooks/`)

`useAudio()`, `useLibrary()` y `useServer()`: hooks de Flutter Hooks que encapsulan el acceso a los providers correspondientes y devuelven objetos con estado y callbacks listos para usar en los widgets.

### Componentes reutilizables (`presentation/components/`)

| Componente  | Descripción                                                                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PlayerBar` | Barra de control de reproducción (barra de progreso, tiempo, botones play/pausa/anterior/siguiente, shuffle, repeat)                                |
| `SongTile`  | Item de lista de canción con artwork (`QueryArtworkWidget`), título, artista, álbum, duración, indicador de reproducción activa y botón de favorito |
| `QRWidget`  | Panel con código QR, URL del servidor y contador de clientes conectados                                                                             |

### Páginas (`presentation/pages/`)

| Página             | Descripción                                                                                                                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `LibraryPage`      | Pantalla principal. Tabs: Canciones, Álbumes, Artistas. Barra de búsqueda. Acceso a Favoritos, Servidor y logout. Integra `PlayerBar`.                                                                                    |
| `PlayerPage`       | Pantalla de reproducción completa. Artwork grande, controles, volumen, cola, letras sincronizadas (`.lrc` desde servidor), paleta de colores por canción.                                                                 |
| `ServerPage`       | Gestión del servidor local. Muestra QR y URL. En móvil también permite escanear QR para conectar a otro servidor.                                                                                                         |
| `LoginPage`        | Autenticación. En web incluye campo para ingresar URL de servidor manualmente y maneja parámetro `?serverUrl=` en la URL.                                                                                                 |
| `RegisterPage`     | Registro de usuario con validación de campos (username, email, contraseña, confirmación).                                                                                                                                 |
| `FavoritesPage`    | Lista de canciones favoritas del usuario con opción de remover y reproducir.                                                                                                                                              |
| `AlbumDetailPage`  | Vista detallada de un álbum con artwork, info, lista de canciones y toggle de favorito.                                                                                                                                   |
| `ArtistDetailPage` | Vista detallada de un artista con artwork, nombre, botón "Reproducir todo" y lista de canciones.                                                                                                                          |
| `WebLibraryPage`   | **Página para navegador web.** Conecta al servidor local via HTTP (lista canciones) y WebSocket (sincronización de estado). Reproduce audio con elemento HTML5 `<audio>`. Reintentos automáticos con backoff exponencial. |

### Redux (secundario) (`presentation/redux/`)

Estructura de store Redux preparada (`AppState`, `PlayerState`, `LibraryState`, `ServerState`) con `appReducer` y `appMiddleware`. Actualmente la gestión de estado principal se realiza con Provider; Redux está preparado pero no completamente utilizado.

---

## Arquitectura y patrones

| Patrón                        | Uso                                      |
| ----------------------------- | ---------------------------------------- |
| **Clean Architecture**        | Separación Domain / Data / Presentation  |
| **Repository Pattern**        | Abstracción del acceso a datos           |
| **Use Cases**                 | Encapsulación de lógica de negocio       |
| **Provider + ChangeNotifier** | State management principal               |
| **Flutter Hooks**             | Lógica reutilizable en widgets           |
| **GetIt (DI)**                | Inyección de dependencias con singletons |
| **Shelf (HTTP)**              | Servidor HTTP/WebSocket embebido         |
| **Redux**                     | Estructura preparada (uso parcial)       |

---

## Comportamiento por plataforma

### Móvil (Android / iOS)

- Accede a la biblioteca local vía `on_audio_query`
- Reproduce localmente con `just_audio`
- Levanta servidor HTTP en el puerto `8765`
- Genera QR para conexión fácil desde navegador

### Web (navegador)

- No accede al sistema de archivos local
- Se conecta vía WebSocket al servidor del móvil
- Obtiene lista de canciones vía `GET /songs`
- Reproduce con elemento HTML5 `<audio>`
- Permite ingresar URL manualmente o recibirla por parámetro en la URL

### Desktop (macOS / Windows / Linux)

- Funcionalidad similar al móvil (biblioteca local y servidor)
- La compilación para macOS está verificada (`flutter build macos` ✓)

---

## Dependencias principales

| Categoría        | Paquetes                                                                  |
| ---------------- | ------------------------------------------------------------------------- |
| Audio            | `just_audio`, `audio_service`, `audio_session`, `on_audio_query`          |
| Servidor         | `shelf`, `shelf_router`, `shelf_web_socket`                               |
| WebSocket        | `web_socket_channel`                                                      |
| QR               | `qr_flutter`, `mobile_scanner`                                            |
| State Management | `provider`, `flutter_hooks`, `flutter_redux`, `redux`                     |
| DI               | `get_it`                                                                  |
| Almacenamiento   | `shared_preferences`, `sqflite`, `path_provider`, `flutter_cache_manager` |
| Red              | `connectivity_plus`, `network_info_plus`, `http`                          |
| Utilidades       | `uuid`, `intl`, `equatable`, `rxdart`                                     |
