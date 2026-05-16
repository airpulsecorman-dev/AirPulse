# 🎵 AirPulse

**AirPulse** es una aplicación profesional de reproductor de música multiplataforma construida con **Flutter**. Es un sistema completo de streaming de música local con capacidades avanzadas de servidor HTTP/WebSocket, compartición P2P, gestión de suscripciones, sistema de favoritos con SQLite, integración con Firebase, y soporte para túneles públicos via ngrok.

---

## 🌟 ¿De qué va el proyecto?

AirPulse es un reproductor de música de nivel empresarial que funciona en **múltiples modos**:

### 1️⃣ **Modo Local (Móvil/Desktop)**

- ✅ Acceso completo a la biblioteca de audio del dispositivo
- ✅ Organización por canciones, álbumes, artistas y playlists
- ✅ Reproducción con controles avanzados (play, pausa, siguiente, anterior, shuffle, repeat)
- ✅ Control de volumen sincronizado con el sistema
- ✅ Búsqueda en tiempo real
- ✅ Sistema de favoritos persistente con SQLite
- ✅ Gestión de playlists personalizadas
- ✅ Letras sincronizadas (archivos .lrc)
- ✅ Paleta de colores adaptativa por canción
- ✅ Metadata completa con artwork

### 2️⃣ **Modo Servidor HTTP/WebSocket (WiFi Local)**

- 🌐 Servidor HTTP embebido en puerto `8765` con **Shelf**
- 🔌 WebSocket bidireccional para sincronización en tiempo real
- 📱 Genera código QR automáticamente para conexión instantánea
- 🎧 Streaming de audio a navegadores via `<audio>` HTML5
- 🔄 Broadcast de estado del reproductor a todos los clientes conectados
- 🌍 Acceso desde cualquier dispositivo en la misma red WiFi
- 📊 Gestión de sesiones y clientes conectados
- 🎨 Web app alojada en GitHub Pages: `https://18-anth.github.io/AirPulseWeb`

### 3️⃣ **Modo Túnel Público (Internet via Ngrok)**

- 🌐 Exposición del servidor local a Internet via túnel HTTPS
- 🔐 Autenticación automática con authtoken
- 📲 Acceso remoto desde cualquier lugar del mundo
- 🔒 Túnel seguro encriptado
- 📱 Solo disponible en Android (ngrok-java nativo)

### 4️⃣ **Modo Compartir P2P (Nearby Connections)**

- 📡 Compartir canciones directamente entre dispositivos
- 🔵 Bluetooth + WiFi Direct (sin Internet)
- 📤 Transferencia de archivos de audio completos
- 📊 Progreso en tiempo real de transferencias
- 👥 Descubrimiento automático de dispositivos cercanos
- 🔄 Roles: Advertiser (comparte) y Discoverer (recibe)

### 5️⃣ **Sistema de Autenticación y Usuarios**

- 🔐 Firebase Authentication (Email/Password + Google Sign-In)
- 👤 Gestión de perfiles de usuario
- 🖼️ Avatares personalizados
- 🔑 Cambio de contraseña
- 📝 Edición de perfil (nombre, apellido, email)
- 🔒 Sesiones seguras persistentes

### 6️⃣ **Sistema de Suscripciones Premium**

- 💳 5 planes de suscripción (Free, Starter, Pro, Premium, Elite)
- 💰 Precios desde $0 hasta $10/mes
- 💳 Métodos de pago: Tarjeta de Crédito, Débito, PayPal
- 🎯 Control de características por plan
- 🔒 Bloqueo inteligente de funciones premium
- 📊 Historial de transacciones
- 💾 Almacenamiento variable según plan (1GB - 200GB)

### 7️⃣ **Sistema de Sesiones QR Web (Estilo WhatsApp Web)**

- 📱 Escaneo de QR en móvil para aprobar sesión web
- ⏱️ Sesiones temporales con expiración (5 minutos)
- 🔥 Firebase Realtime Database para sincronización
- 🔐 Autenticación sin contraseña
- 🌐 Aprobación/rechazo desde el móvil

---

## 📁 Estructura de la Carpeta `lib/`

La carpeta `lib/` sigue los principios de **Clean Architecture** con separación estricta de capas:

```bash
lib/
├── main.dart                           # 🚀 Punto de entrada
├── firebase_options.dart               # 🔥 Configuración Firebase multiplataforma
│
├── app/
│   └── app.dart                        # 🏠 Widget raíz + AuthGate
│
├── core/                               # ⚙️ Módulo transversal
│   ├── config/
│   │   └── env_loader.dart            # 📦 Carga variables de entorno (.env)
│   ├── constants/
│   │   └── app_constants.dart         # 🔢 Constantes globales
│   ├── di/
│   │   └── service_locator.dart       # 💉 Inyección de dependencias (GetIt)
│   └── utils/
│       ├── duration_utils.dart        # ⏱️ Formateo de duración (mm:ss)
│       ├── file_utils.dart            # 📄 Validación de archivos de audio
│       └── network_utils.dart         # 🌐 WiFi, URLs del servidor
│
├── domain/                             # 🎯 Capa de Dominio (pura)
│   ├── entities/                      # 📦 Entidades de negocio
│   │   ├── song.dart                 # 🎵 Canción
│   │   ├── album.dart                # 💿 Álbum
│   │   ├── artist.dart               # 🎤 Artista
│   │   ├── playlist.dart             # 📝 Playlist
│   │   ├── user.dart                 # 👤 Usuario
│   │   ├── server_session.dart       # 🌐 Sesión del servidor
│   │   ├── subscription_plan.dart    # 💎 Plan de suscripción
│   │   └── user_subscription.dart    # 💳 Suscripción activa del usuario
│   │
│   ├── repositories/                  # 📋 Interfaces (contratos)
│   │   ├── auth_repository.dart
│   │   ├── library_repository.dart
│   │   ├── player_repository.dart
│   │   ├── favorites_repository.dart
│   │   ├── server_repository.dart
│   │   └── subscription_repository.dart
│   │
│   └── usecases/                      # 🎯 Casos de uso (lógica de negocio)
│       ├── auth_usecases.dart         # Login, Register, Logout
│       ├── library_usecases.dart      # Cargar biblioteca, búsqueda
│       ├── player_usecases.dart       # Play, Pause, Seek, Queue
│       ├── favorites_usecases.dart    # Add, Remove, Toggle, Clean
│       ├── server_usecases.dart       # Start/Stop server, Broadcast
│       └── subscription_usecases.dart # Upgrade, Downgrade, Check features
│
├── data/                               # 💾 Capa de Datos (implementación)
│   ├── models/                        # 📦 Modelos con JSON serialization
│   │   ├── song_model.dart
│   │   ├── album_model.dart
│   │   ├── playlist_model.dart
│   │   ├── user_model.dart
│   │   ├── server_session_model.dart
│   │   ├── subscription_model.dart
│   │   └── favorite_song_model.dart   # Para SQLite
│   │
│   ├── sources/
│   │   ├── local/                     # 📱 Fuentes de datos locales
│   │   │   ├── library_local_source.dart      # on_audio_query
│   │   │   ├── audio_local_source.dart        # just_audio
│   │   │   └── favorites_database.dart        # 🗄️ SQLite
│   │   │
│   │   └── remote/                    # 🌐 Fuentes de datos remotas
│   │       └── websocket_source.dart  # Gestión de clientes WS
│   │
│   └── repositories/                  # 🔄 Implementaciones
│       ├── firebase_auth_repository_impl.dart # Firebase Auth
│       ├── library_repository_impl.dart
│       ├── player_repository_impl.dart
│       ├── favorites_repository_impl.dart     # SQLite
│       └── subscription_repository_impl.dart  # SharedPreferences
│
├── services/                           # 🎭 Capa de Orquestación (Fachada)
│   ├── audio_service.dart             # 🎵 Coordina reproducción
│   ├── audio_handler.dart             # 📻 Background audio (audio_service)
│   ├── library_service.dart           # 📚 Gestión de biblioteca
│   ├── local_server_service.dart      # 🌐 Servidor HTTP/WebSocket (Shelf)
│   ├── nearby_share_service.dart      # 📡 P2P Bluetooth/WiFi Direct
│   ├── ngrok_service.dart             # 🌍 Túneles HTTPS públicos
│   ├── qr_service.dart                # 📲 Generación/escaneo QR
│   ├── qr_session_service.dart        # 🔐 Sesiones QR estilo WhatsApp Web
│   ├── payment_service.dart           # 💳 Procesamiento de pagos
│   └── system_volume_service.dart     # 🔊 Sincronización volumen del sistema
│
└── presentation/                       # 🎨 Capa de Presentación (UI)
    ├── providers/                     # 🔔 State Management (Provider)
    │   ├── audio_provider.dart        # 🎵 Estado del reproductor
    │   ├── auth_provider.dart         # 🔐 Estado de autenticación
    │   ├── library_provider.dart      # 📚 Estado de biblioteca
    │   ├── server_provider.dart       # 🌐 Estado del servidor
    │   ├── favorites_provider.dart    # 💖 Estado de favoritos
    │   └── settings_provider.dart     # ⚙️ Configuraciones
    │
    ├── controllers/                   # 🎮 Controladores (lógica de UI)
    │   ├── library_controller.dart
    │   ├── player_controller.dart
    │   └── server_controller.dart
    │
    ├── hooks/                         # 🪝 Custom Hooks (Flutter Hooks)
    │   ├── use_audio.dart
    │   ├── use_library.dart
    │   ├── use_server.dart
    │   └── use_subscription.dart
    │
    ├── components/                    # 🧩 Componentes reutilizables
    │   ├── player_bar.dart            # 🎵 Barra de reproducción inferior
    │   ├── song_tile.dart             # 🎼 Item de lista de canción
    │   ├── favorite_button.dart       # 💖 Botón animado de favorito
    │   ├── feature_guard.dart         # 🔒 Bloqueo de características premium
    │   ├── payment_form_dialog.dart   # 💳 Formulario de pago
    │   ├── qr_widget.dart             # 📲 Widget de código QR
    │   └── song_artwork.dart          # 🖼️ Artwork de canción
    │
    ├── widgets/                       # 🎨 Widgets específicos
    │   └── share_options_dialog.dart  # 📤 Opciones de compartir
    │
    ├── pages/                         # 📄 Pantallas de la app
    │   ├── library_page.dart          # 📚 Pantalla principal de biblioteca
    │   ├── player_page.dart           # 🎵 Reproductor completo
    │   ├── server_page.dart           # 🌐 Gestión del servidor
    │   ├── login_page.dart            # 🔐 Inicio de sesión
    │   ├── register_page.dart         # 📝 Registro de usuario
    │   ├── favorites_page.dart        # 💖 Lista de favoritos
    │   ├── album_detail_page.dart     # 💿 Detalle de álbum
    │   ├── artist_detail_page.dart    # 🎤 Detalle de artista
    │   ├── pricing_page.dart          # 💎 Planes de suscripción
    │   ├── profile_page.dart          # 👤 Perfil de usuario
    │   ├── edit_profile_page.dart     # ✏️ Editar perfil
    │   ├── change_password_page.dart  # 🔑 Cambiar contraseña
    │   ├── settings_page.dart         # ⚙️ Configuraciones
    │   ├── nearby_share_page.dart     # 📡 Compartir P2P
    │   ├── google_onboarding_page.dart# 🔐 Onboarding Google Sign-In
    │   ├── web_library_page.dart      # 🌐 Biblioteca para navegador
    │   ├── server_webview_page.dart   # 🌐 WebView para servidor
    │   ├── privacy_policy_page.dart   # 📜 Política de privacidad
    │   ├── terms_page.dart            # 📜 Términos y condiciones
    │   └── intellectual_property_page.dart # ©️ Propiedad intelectual
    │
    └── redux/                         # 🔄 Redux (preparado, uso parcial)
        ├── app_state.dart
        ├── app_reducer.dart
        ├── app_middleware.dart
        └── store.dart
```

---

## 🚀 `main.dart` — Punto de Entrada

Configuración inicial de la aplicación:

1. **Inicialización de Flutter:** `WidgetsFlutterBinding.ensureInitialized()`
2. **Firebase:** `Firebase.initializeApp()` con configuración multiplataforma
3. **Audio Background:** Inicializa `AudioHandler` con `audio_service`
4. **Inyección de Dependencias:** `setupDependencies()` con GetIt
5. **Variables de Entorno:** Carga credenciales desde `assets/env.txt`
6. **Providers:** Configura `MultiProvider` con todos los providers de estado
7. **Navegación:** Rutas nombradas para todas las pantallas

---

## 🏠 `app/` — Widget Raíz y Auth Gate

### `AirPulseApp`

Widget raíz que configura:

- **MultiProvider:** Audio, Library, Auth, Favorites, Server, Settings
- **Tema Material 3:** Modo oscuro por defecto, color primario `#6750A4`
- **Rutas nombradas:** `/`, `/player`, `/server`, `/login`, `/register`, `/favorites`, `/pricing`, `/profile`, etc.
- **Localización:** Soporte para español e inglés
- **Modo de debugging:** DevTools habilitado

### `_AuthGate`

Puerta de autenticación que decide la pantalla inicial:

- **Web:** Siempre muestra `LoginPage`
- **Móvil:** Verifica estado de autenticación
  - ✅ Autenticado → `LibraryPage`
  - ❌ No autenticado → `LoginPage`
  - ⏳ Desconocido → Loading screen

---

## ⚙️ `core/` — Módulo Transversal

### 📦 `config/env_loader.dart`

Carga variables de entorno desde `assets/env.txt`:

- API Keys de Firebase
- Auth Tokens (Ngrok, Stripe, PayPal)
- URLs de configuración
- Secrets encriptados

**Formato del archivo `.env`:**

```bash
API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXX
AUTH_DOMAIN=airpulse-xxxxx.firebaseapp.com
DATABASE_URL=https://airpulse-xxxxx.firebaseio.com
PROJECT_ID=airpulse-xxxxx
STORAGE_BUCKET=airpulse-xxxxx.appspot.com
MESSAGING_SENDER_ID=123456789012
APP_ID=1:123456789012:web:abcdef123456
ANDROID_APP_ID=1:123456789012:android:abcdef123456
IOS_APP_ID=1:123456789012:ios:abcdef123456
MEASUREMENT_ID=G-XXXXXXXXXX
NGROK_AUTHTOKEN=3DNRmnh96kv1pNGMOQ0vOLNlyQL_3Br7DyYiLyGJQe8BNJij2
```

### 🔢 `constants/app_constants.dart`

Constantes globales:

```dart
static const String appName = 'AirPulse';
static const String appVersion = '1.0.0';
static const int serverPort = 8765;
static const String webAppUrl = 'https://18-anth.github.io/AirPulseWeb';
static const int connectionTimeout = 10; // segundos
static const int maxReconnectAttempts = 5;
static const Duration sessionExpirationTime = Duration(minutes: 5);
```

### 💉 `di/service_locator.dart`

Inyección de dependencias con **GetIt**:

- ✅ Registra todos los servicios como singletons
- ✅ Inicializa bases de datos (SQLite para favoritos)
- ✅ Configura repositorios con sus fuentes de datos
- ✅ Inyecta use cases con sus dependencias

**Servicios registrados:**

- `AudioService`, `AudioHandler`
- `LibraryService`
- `LocalServerService`
- `NearbyShareService`
- `NgrokService`
- `QRService`, `QRSessionService`
- `PaymentService`
- `SystemVolumeService`
- `FavoritesDatabase`
- Todos los repositorios
- Todos los providers

### 🛠️ `utils/`

| Archivo               | Funciones                                                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `duration_utils.dart` | • `formatDuration(Duration)` → `"3:45"`<br>• `playbackProgress(position, duration)` → `0.0-1.0`                                         |
| `file_utils.dart`     | • `isSupportedAudio(path)` → Valida mp3, flac, aac, ogg, wav, m4a, opus<br>• `readableFileSize(bytes)` → `"3.5 MB"`                     |
| `network_utils.dart`  | • `hasWifiConnection()` → `bool`<br>• `buildStreamUrl(ip, port, songId)` → URL completa<br>• `buildWebSocketUrl(ip, port)` → `ws://...` |

---

## 🎯 `domain/` — Capa de Dominio (Lógica de Negocio Pura)

### 📦 Entidades (`domain/entities/`)

#### 🎵 `Song`

```dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;           // Ruta local del archivo
  final int duration;              // Milisegundos
  final String? artworkPath;       // Ruta del artwork
  final int? trackNumber;
  final DateTime? dateAdded;
  final String? genre;
  final int? year;
  final int? bitrate;
  final String? composer;
}
```

#### 💿 `Album`

```dart
class Album {
  final String id;
  final String title;
  final String artist;
  final String? artworkPath;
  final int? year;
  final List<Song> songs;
  final int songCount;
}
```

#### 🎤 `Artist`

```dart
class Artist {
  final String id;
  final String name;
  final String? artworkPath;
  final List<Song> songs;
  final int songCount;
  final int albumCount;
}
```

#### 📝 `Playlist`

```dart
class Playlist {
  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final String? artworkPath;       // Artwork de la primera canción
  final int songCount;
  final Duration totalDuration;
}
```

#### 👤 `User`

```dart
class User {
  final String id;
  final String username;
  final String email;
  final String? avatarPath;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final DateTime? lastLogin;
}
```

#### 🌐 `ServerSession`

```dart
enum ServerStatus { stopped, starting, running, error }

class ServerSession {
  final String sessionId;
  final String localIp;
  final int port;
  final ServerStatus status;
  final String qrPayload;          // JSON para QR
  final List<String> connectedClients;
  final DateTime? startedAt;
  final String? errorMessage;
  final String? ngrokUrl;          // URL pública si está activo
}
```

#### 💎 `SubscriptionPlan`

```dart
enum PlanType { free, starter, pro, premium, elite }

class SubscriptionPlan {
  final PlanType type;
  final String name;
  final double price;              // USD por mes
  final String currency;
  final List<String> features;
  final int storageGB;
  final bool adsEnabled;
  final bool offlineMode;
  final bool hdQuality;
  final bool losslessQuality;
  final bool familySharing;
  final int maxDevices;
}
```

#### 💳 `UserSubscription`

```dart
enum SubscriptionStatus { active, expired, cancelled, paused }

class UserSubscription {
  final String id;
  final String userId;
  final PlanType planType;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? expirationDate;
  final DateTime? cancelledAt;
  final String? paymentMethod;
  final double amountPaid;
  final bool autoRenew;
}
```

### 📋 Repositorios — Interfaces (`domain/repositories/`)

#### 🔐 `AuthRepository`

```dart
abstract class AuthRepository {
  Future<User> register(String username, String email, String password);
  Future<User> login(String email, String password);
  Future<User?> loginWithGoogle();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
  Future<void> updateProfile(User user);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> resetPassword(String email);
  Stream<User?> get authStateChanges;
}
```

#### 📚 `LibraryRepository`

```dart
abstract class LibraryRepository {
  Future<List<Song>> getAllSongs();
  Future<List<Album>> getAllAlbums();
  Future<List<Artist>> getAllArtists();
  Future<List<Playlist>> getAllPlaylists();
  Future<List<Song>> searchSongs(String query);
  Future<Playlist> createPlaylist(String name);
  Future<void> addSongToPlaylist(String playlistId, Song song);
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
  Future<void> deletePlaylist(String playlistId);
  Future<void> requestPermissions();
  Stream<List<Song>> get songsStream;
}
```

#### 🎵 `PlayerRepository`

```dart
abstract class PlayerRepository {
  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setQueue(List<Song> songs, int initialIndex);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setRepeatMode(RepeatMode mode);
  Future<void> setShuffleEnabled(bool enabled);

  Stream<bool> get isPlayingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<double> get volumeStream;
  Stream<int?> get currentIndexStream;
  Stream<Song?> get currentSongStream;
}
```

#### 💖 `FavoritesRepository`

```dart
abstract class FavoritesRepository {
  Future<List<Song>> getFavorites(String userId);
  Future<void> addFavorite(String userId, Song song);
  Future<void> removeFavorite(String userId, String songId);
  Future<bool> isFavorite(String userId, String songId);
  Future<bool> toggleFavorite(String userId, Song song);
  Future<int> cleanInvalidFavorites(String userId);
  Future<int> getFavoritesCount(String userId);
  Future<List<Song>> searchFavorites(String userId, String query);
  Future<void> clearAllFavorites(String userId);
  Future<Map<String, dynamic>> getStatistics(String userId);
}
```

#### 🌐 `ServerRepository`

```dart
abstract class ServerRepository {
  Future<ServerSession> startServer({bool enableNgrok = false});
  Future<void> stopServer();
  Future<ServerSession?> getActiveSession();
  Future<void> broadcastPlayerState(Map<String, dynamic> state);
  Future<void> sendToClient(String clientId, Map<String, dynamic> data);
  Stream<List<String>> get connectedClientsStream;
  Stream<Map<String, dynamic>> get commandsStream;
}
```

#### 💳 `SubscriptionRepository`

```dart
abstract class SubscriptionRepository {
  Future<UserSubscription?> getUserSubscription(String userId);
  Future<void> createSubscription(String userId, PlanType planType, String paymentMethod);
  Future<void> upgradeSubscription(String userId, PlanType newPlanType);
  Future<void> cancelSubscription(String userId);
  Future<List<SubscriptionPlan>> getAvailablePlans();
  Future<bool> hasFeatureAccess(String userId, String featureName);
  Future<Map<String, dynamic>> getSubscriptionStatistics(String userId);
}
```

### 🎯 Casos de Uso (`domain/usecases/`)

#### 🔐 `auth_usecases.dart`

- `LoginUseCase` — Inicia sesión con email/password
- `RegisterUseCase` — Registra nuevo usuario
- `LoginWithGoogleUseCase` — Autenticación con Google
- `LogoutUseCase` — Cierra sesión
- `GetCurrentUserUseCase` — Obtiene usuario actual
- `UpdateProfileUseCase` — Actualiza perfil
- `ChangePasswordUseCase` — Cambia contraseña

#### 📚 `library_usecases.dart`

- `GetLibraryUseCase` — Carga biblioteca completa
- `SearchSongsUseCase` — Busca canciones
- `CreatePlaylistUseCase` — Crea playlist
- `ManagePlaylistUseCase` — Gestiona canciones en playlist

#### 🎵 `player_usecases.dart`

- `PlaySongUseCase` — Reproduce una canción
- `ControlPlaybackUseCase` — Pausa, resume, stop
- `SeekUseCase` — Navega en la canción
- `ManageQueueUseCase` — Gestiona cola de reproducción
- `SetRepeatModeUseCase` — Configura repeat
- `ToggleShuffleUseCase` — Activa/desactiva shuffle

#### 💖 `favorites_usecases.dart`

- `GetFavoritesUseCase` — Obtiene favoritos
- `AddFavoriteUseCase` — Agrega a favoritos
- `RemoveFavoriteUseCase` — Elimina de favoritos
- `ToggleFavoriteUseCase` — Alterna estado
- `IsFavoriteUseCase` — Verifica si es favorito
- `CleanInvalidFavoritesUseCase` — Limpia favoritos con archivos eliminados
- `GetFavoritesCountUseCase` — Cuenta total
- `SearchFavoritesUseCase` — Busca en favoritos
- `ClearAllFavoritesUseCase` — Elimina todos
- `GetFavoritesStatisticsUseCase` — Estadísticas

#### 🌐 `server_usecases.dart`

- `StartServerUseCase` — Inicia servidor local
- `StopServerUseCase` — Detiene servidor
- `BroadcastStateUseCase` — Difunde estado del reproductor
- `ManageClientsUseCase` — Gestiona clientes conectados

#### 💳 `subscription_usecases.dart`

- `GetUserSubscriptionUseCase` — Obtiene suscripción activa
- `UpgradeSubscriptionUseCase` — Actualiza plan
- `CancelSubscriptionUseCase` — Cancela suscripción
- `CheckFeatureAccessUseCase` — Verifica acceso a característica
- `GetAvailablePlansUseCase` — Lista planes disponibles

---

## 💾 `data/` — Capa de Datos (Implementación)

### 📦 Modelos (`data/models/`)

Cada modelo extiende su entidad de dominio y añade:

- ✅ `fromJson(Map<String, dynamic>)` — Deserialización
- ✅ `toJson()` — Serialización
- ✅ `fromEntity(Entity)` — Conversión desde entidad de dominio
- ✅ `toEntity()` — Conversión a entidad de dominio
- ✅ `copyWith()` — Copia inmutable con cambios

**Modelos disponibles:**

- `SongModel`, `AlbumModel`, `ArtistModel`, `PlaylistModel`
- `UserModel`, `ServerSessionModel`, `SubscriptionModel`
- `FavoriteSongModel` (específico para SQLite)

### 📱 Fuentes de Datos Locales (`data/sources/local/`)

#### 🎵 `LibraryLocalSource`

**Plugin:** `on_audio_query`

**Funcionalidades:**

- ✅ Solicita permisos de almacenamiento/audio (Android 13+)
- ✅ Lee biblioteca de audio del dispositivo
- ✅ Filtra archivos no musicales (WhatsApp, Recordings, etc.)
- ✅ Extrae metadata: título, artista, álbum, duración, artwork
- ✅ Organiza por canciones, álbumes y artistas
- ✅ Caché inteligente para artwork

**Permisos requeridos:**

```xml
<!-- Android -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/> <!-- Android 13+ -->
```

#### 🎧 `AudioLocalSource`

**Plugin:** `just_audio`

**Funcionalidades:**

- ✅ Reproducción de audio local y streaming
- ✅ Control completo: play, pause, resume, stop, seek
- ✅ Gestión de cola (queue)
- ✅ Repeat modes: off, one, all
- ✅ Shuffle mode
- ✅ Control de volumen (0.0 - 1.0)
- ✅ Streams reactivos de estado

**Streams expuestos:**

```dart
Stream<bool> isPlayingStream;
Stream<Duration> positionStream;
Stream<Duration?> durationStream;
Stream<double> volumeStream;
Stream<int?> currentIndexStream;
Stream<Song?> currentSongStream;
```

#### 🗄️ `FavoritesDatabase`

**Backend:** SQLite con plugin `sqflite`

**Tabla `favorite_songs`:**

```sql
CREATE TABLE favorite_songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  file_path TEXT NOT NULL,            -- UNIQUE per user
  duration_ms INTEGER NOT NULL,
  artwork_path TEXT,
  track_number INTEGER DEFAULT 0,
  date_added TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, song_id) ON CONFLICT REPLACE
);

-- Índices para optimización
CREATE INDEX idx_user_id ON favorite_songs(user_id);
CREATE INDEX idx_song_id ON favorite_songs(song_id);
CREATE INDEX idx_file_path ON favorite_songs(file_path);
CREATE INDEX idx_created_at ON favorite_songs(created_at DESC);
```

**Optimizaciones SQLite:**

```dart
PRAGMA foreign_keys = ON;           // Integridad referencial
PRAGMA journal_mode = WAL;          // Write-Ahead Logging
PRAGMA synchronous = NORMAL;        // Balance seguridad/rendimiento
PRAGMA cache_size = 10000;          // Cache de 10MB
PRAGMA temp_store = MEMORY;         // Tablas temporales en RAM
```

**Funcionalidades:**

- ✅ Persistencia local sin red
- ✅ Sin duplicación de archivos (solo metadata)
- ✅ Validación automática de archivos existentes
- ✅ Queries optimizadas con índices
- ✅ Búsqueda full-text
- ✅ Estadísticas de uso

### 🌐 Fuentes de Datos Remotas (`data/sources/remote/`)

#### 🔌 `WebSocketSource`

Gestiona conexiones WebSocket bidireccionales.

**Funcionalidades:**

- ✅ Gestión de múltiples clientes conectados
- ✅ `broadcast(data)` — Envía a todos los clientes
- ✅ `sendToClient(clientId, data)` — Envía a uno específico
- ✅ Streams de comandos recibidos
- ✅ Heartbeat para detectar desconexiones
- ✅ Reconexión automática

**Protocolo de mensajes:**

```json
{
  "type": "command|state|response",
  "action": "play|pause|seek|volume|...",
  "data": { ... },
  "timestamp": 1234567890
}
```

### 🔄 Implementaciones de Repositorios (`data/repositories/`)

#### 🔐 `FirebaseAuthRepositoryImpl`

**Backend:** Firebase Authentication + Realtime Database

**Autenticación:**

- ✅ Email/Password
- ✅ Google Sign-In
- ✅ Gestión de sesiones persistentes
- ✅ Tokens de autenticación automáticos

**Almacenamiento de perfiles:**

```json
{
  "users": {
    "{userId}": {
      "username": "john_doe",
      "email": "john@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "avatarPath": "gs://...",
      "createdAt": "2024-01-01T00:00:00Z",
      "lastLogin": "2024-05-16T10:30:00Z"
    }
  }
}
```

#### 📚 `LibraryRepositoryImpl`

**Fuentes:**

- Local: `LibraryLocalSource` (on_audio_query)
- Memoria: Playlists en `List<Playlist>`

**Caché:**

- Canciones, álbumes y artistas se cachean en memoria
- Refresh manual o automático cada 10 minutos

#### 🎵 `PlayerRepositoryImpl`

**Fuente:** `AudioLocalSource` (just_audio)

**Audio Background:**
Integración con `audio_service` para:

- ✅ Reproducción en segundo plano
- ✅ Notificaciones de media
- ✅ Control desde lockscreen
- ✅ Control desde auriculares/Bluetooth

#### 💖 `FavoritesRepositoryImpl`

**Backend:** SQLite via `FavoritesDatabase`

**Operaciones:**

- ✅ CRUD completo de favoritos
- ✅ Validación de archivos en lectura
- ✅ Limpieza automática de favoritos inválidos
- ✅ Búsqueda con LIKE %query%
- ✅ Caché en memoria para queries recientes

#### 💳 `SubscriptionRepositoryImpl`

**Backend:** SharedPreferences (local)

**Estructura de datos:**

```dart
// Key: user_subscription_{userId}
{
  "planType": "premium",
  "status": "active",
  "startDate": "2024-01-01T00:00:00Z",
  "expirationDate": "2025-01-01T00:00:00Z",
  "paymentMethod": "credit_card",
  "amountPaid": 5.0,
  "autoRenew": true
}
```

**Control de características:**

```dart
Map<String, List<PlanType>> featureAccess = {
  'offline_mode': [PlanType.starter, PlanType.pro, PlanType.premium, PlanType.elite],
  'quality_selection': [PlanType.pro, PlanType.premium, PlanType.elite],
  'lossless_quality': [PlanType.premium, PlanType.elite],
  'family_sharing': [PlanType.elite],
  // ...
};
```

---

## 🎭 `services/` — Capa de Orquestación (Fachada)

Los servicios actúan como fachada entre la presentación y el dominio/data, coordinando múltiples repositorios y lógica compleja.

### 🎵 `AudioService`

**Responsabilidad:** Coordina la reproducción de audio y gestiona el estado del reproductor.

**Estado interno:**

```dart
Song? _currentSong;
List<Song> _queue;
int _currentIndex;
RepeatMode _repeatMode;  // off, one, all
bool _shuffleEnabled;
Duration _position;
Duration? _duration;
double _volume;
bool _isPlaying;
```

**Funcionalidades clave:**

- ✅ Gestión de cola de reproducción
- ✅ Shuffle (mezcla aleatoria de canciones)
- ✅ Repeat modes (repetir todo, una, o ninguna)
- ✅ Serialización de estado a JSON para broadcast WebSocket
- ✅ Streams reactivos para la UI
- ✅ Auto-play siguiente canción al terminar
- ✅ Persistencia de estado de reproducción

**Serialización para WebSocket:**

```json
{
  "currentSong": { "id": "123", "title": "...", "artist": "..." },
  "isPlaying": true,
  "position": 45000,
  "duration": 180000,
  "volume": 0.8,
  "repeatMode": "all",
  "shuffleEnabled": true,
  "queue": [ ... ]
}
```

### 📻 `AudioHandler`

**Plugin:** `audio_service`

**Responsabilidad:** Gestiona audio en segundo plano y notificaciones de media.

**Funcionalidades:**

- ✅ Reproducción en segundo plano (background)
- ✅ Notificación de media con controles
- ✅ Control desde lockscreen
- ✅ Control desde auriculares Bluetooth
- ✅ Integración con Android Auto / CarPlay
- ✅ Botones de acción personalizables

**Notificación de media:**

```bash
┌─────────────────────────────────┐
│ 🎵 AirPulse                     │
│                                 │
│ Never Gonna Give You Up         │
│ Rick Astley                     │
│                                 │
│ ⏮️  ⏯️  ⏭️    [artwork]        │
└─────────────────────────────────┘
```

### 📚 `LibraryService`

**Responsabilidad:** Gestiona la carga y búsqueda de la biblioteca musical.

**Funcionalidades:**

- ✅ Solicitud de permisos de almacenamiento
- ✅ Carga de canciones con filtrado
- ✅ Organización por álbumes y artistas
- ✅ Búsqueda en tiempo real
- ✅ Caché de metadata
- ✅ Refresh periódico de biblioteca

**Filtros aplicados:**

- ❌ WhatsApp Audio
- ❌ Recordings / Grabaciones
- ❌ Notifications / Ringtones
- ❌ Archivos < 30 segundos
- ❌ Formatos no soportados

### 🌐 `LocalServerService`

**Plugin:** `shelf` + `shelf_router` + `shelf_web_socket`

**Puerto:** `8765`

**Responsabilidad:** Servidor HTTP/WebSocket embebido para streaming a navegadores.

**Rutas HTTP:**

| Ruta                 | Método | Descripción                               | Content-Type       |
| -------------------- | ------ | ----------------------------------------- | ------------------ |
| `/`                  | GET    | Página HTML con reproductor web embebido  | `text/html`        |
| `/health`            | GET    | Health check                              | `application/json` |
| `/songs`             | GET    | Lista completa de canciones               | `application/json` |
| `/songs/<id>`        | GET    | Información de una canción                | `application/json` |
| `/songs/<id>/stream` | GET    | Stream del archivo de audio               | `audio/mpeg`       |
| `/albums`            | GET    | Lista de álbumes                          | `application/json` |
| `/artists`           | GET    | Lista de artistas                         | `application/json` |
| `/state`             | GET    | Estado actual del reproductor             | `application/json` |
| `/lyrics/<id>`       | GET    | Letras sincronizadas (.lrc)               | `text/plain`       |
| `/artwork/<id>`      | GET    | Artwork de canción/álbum                  | `image/jpeg`       |
| `/ws`                | GET    | WebSocket para comunicación bidireccional | -                  |

**Middleware:**

- ✅ CORS habilitado para todos los orígenes
- ✅ Logging de requests
- ✅ Error handling global
- ✅ Compresión gzip

**Comandos WebSocket:**

```json
// Cliente → Servidor
{ "type": "command", "action": "play", "data": { "songId": "123" } }
{ "type": "command", "action": "pause" }
{ "type": "command", "action": "seek", "data": { "position": 45000 } }
{ "type": "command", "action": "volume", "data": { "level": 0.8 } }
{ "type": "command", "action": "next" }
{ "type": "command", "action": "previous" }

// Servidor → Cliente (broadcast)
{ "type": "state", "data": { ... } }  // Estado del reproductor
{ "type": "notification", "message": "Nueva canción añadida" }
```

**Generación de QR:**

```json
{
  "type": "airpulse_connect",
  "url": "http://192.168.1.100:8765",
  "sessionId": "abc123-def456-ghi789",
  "version": "1"
}
```

### 📡 `NearbyShareService`

**Plugin:** `nearby_connections` (Google Nearby API)

**Tecnologías:** Bluetooth + WiFi Direct (sin Internet)

**Roles:**

#### 📤 **Advertiser (Comparte)**

```dart
await nearbyShare.startAdvertising(username: 'John');
// Espera conexiones entrantes
```

#### 📥 **Discoverer (Recibe)**

```dart
await nearbyShare.startDiscovery();
// Escanea dispositivos cercanos
Stream<List<NearbyDevice>> devicesStream = nearbyShare.devicesStream;
```

**Flujo de compartir canción:**

1. Advertiser inicia modo compartir
2. Discoverer escanea y ve el dispositivo
3. Discoverer solicita conexión
4. Advertiser acepta/rechaza
5. Se envía metadata de la canción
6. Se transfiere el archivo de audio completo
7. Ambos reciben notificación de progreso
8. Se guarda en directorio de descargas del receptor

**Permisos requeridos:**

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>
```

### 🌍 `NgrokService`

**Platform:** Solo Android (via MethodChannel)

**Responsabilidad:** Expone el servidor local a Internet via túnel HTTPS.

**Integración:** Usa `ngrok-java` nativo en Android

**Authtoken:** Configurado en `env.txt`

**Uso:**

```dart
final ngrokService = NgrokService();
String? publicUrl = await ngrokService.startTunnel(8765);
// publicUrl = "https://abc123.ngrok-free.app"
```

**Características:**

- ✅ Túnel HTTPS seguro
- ✅ URL pública estable durante la sesión
- ✅ Sin configuración de firewall
- ✅ Acceso desde cualquier lugar del mundo
- ✅ Latencia mínima

**Configuración nativa (Android):**

```kotlin
// MainActivity.kt
MethodChannel(flutterEngine.dartExecutor, "com.airpulse/ngrok")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "startTunnel" -> {
                val port = call.argument<Int>("port")
                val authtoken = call.argument<String>("authtoken")
                val url = Ngrok.builder()
                    .authtoken(authtoken)
                    .httpEndpoint(BasicTunnelBuilder.HttpEndpoint()
                        .localAddr("127.0.0.1:$port"))
                    .forward()
                    .url()
                result.success(url)
            }
            "stopTunnel" -> {
                Ngrok.disconnect()
                result.success(null)
            }
        }
    }
```

### 📲 `QRService`

**Plugin:** `qr_flutter` (generación) + `mobile_scanner` (escaneo)

**Responsabilidad:** Generación y escaneo de códigos QR.

**Generación:**

```dart
Widget qrWidget = qrService.buildQRWidget(
  payload: '{"type":"airpulse_connect","url":"..."}',
  size: 220,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
);
```

**Escaneo:**

```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => QRScannerPage()),
);
Map<String, dynamic>? data = qrService.parseQRPayload(result);
```

### 🔐 `QRSessionService`

**Backend:** Firebase Realtime Database

**Responsabilidad:** Gestiona sesiones de autenticación QR estilo WhatsApp Web.

**Flujo:**

#### 🌐 **Lado Web:**

1. Genera `sessionId` único
2. Crea nodo en Firebase: `web_sessions/{sessionId}`
3. Muestra QR con el sessionId
4. Escucha cambios en el nodo
5. Cuando status = "approved", obtiene datos del usuario
6. Navega a pantalla principal

#### 📱 **Lado Móvil:**

1. Escanea el QR
2. Extrae `sessionId`
3. Muestra diálogo de confirmación
4. Si aprueba, escribe datos del usuario en Firebase
5. Actualiza status a "approved"
6. Web detecta el cambio y completa login

**Estructura en Firebase:**

```json
{
  "web_sessions": {
    "session_abc123": {
      "status": "pending",
      "createdAt": 1234567890,
      "expiresAt": 1234567890 + 300000,  // 5 minutos
      "approved": false
    }
  }
}
```

**Después de aprobar:**

```json
{
  "web_sessions": {
    "session_abc123": {
      "status": "approved",
      "uid": "user_123",
      "email": "john@example.com",
      "username": "john_doe",
      "firstName": "John",
      "lastName": "Doe",
      "avatarPath": "...",
      "serverUrl": "http://192.168.1.100:8765",
      "approvedAt": 1234567890
    }
  }
}
```

**Seguridad:**

- ✅ Sesiones expiran automáticamente en 5 minutos
- ✅ Una sesión solo se puede aprobar una vez
- ✅ Limpieza automática de sesiones expiradas

### 💳 `PaymentService`

**Responsabilidad:** Procesa pagos para suscripciones.

**Métodos de pago soportados:**

#### 💳 **Tarjeta de Crédito/Débito**

- **Gateway:** Stripe (simulado)
- **Validación:** Algoritmo de Luhn para número de tarjeta
- **CVV:** 3-4 dígitos
- **Expiración:** Validación de fecha

```dart
await paymentService.processCardPayment(
  cardNumber: '4242424242424242',  // Stripe test card
  expiryMonth: 12,
  expiryYear: 2025,
  cvv: '123',
  amount: 5.0,
  currency: 'USD',
);
```

#### 💰 **PayPal**

- **Redirección:** A PayPal para completar transacción
- **Confirmación:** Webhook automático

```dart
await paymentService.processPayPalPayment(
  email: 'john@example.com',
  amount: 5.0,
  currency: 'USD',
);
```

**Historial de transacciones:**

```json
{
  "transactions": [
    {
      "id": "txn_123",
      "userId": "user_123",
      "amount": 5.0,
      "currency": "USD",
      "method": "credit_card",
      "status": "completed",
      "timestamp": 1234567890,
      "planType": "premium"
    }
  ]
}
```

### 🔊 `SystemVolumeService`

**Platform:** Solo Android (via MethodChannel)

**Responsabilidad:** Sincroniza el volumen de la app con el volumen del sistema.

**Funcionamiento:**

1. Listener nativo detecta cambios de volumen del sistema
2. Notifica a Flutter via MethodChannel
3. Flutter actualiza el volumen del reproductor
4. UI se actualiza automáticamente

**Configuración nativa (Android):**

```kotlin
class VolumeObserver(private val channel: MethodChannel) : ContentObserver(Handler(Looper.getMainLooper())) {
    override fun onChange(selfChange: Boolean) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val volumeLevel = currentVolume.toDouble() / maxVolume
        channel.invokeMethod("onVolumeChanged", volumeLevel)
    }
}
```

---

## 🎨 `presentation/` — Capa de Presentación (UI)

### 🔔 Providers (`presentation/providers/`)

State management con **ChangeNotifier + Provider**. Todos los providers notifican cambios a la UI automáticamente.

#### 🎵 `AudioProvider`

**Estado gestionado:**

```dart
Song? currentSong;
bool isPlaying;
Duration position;
Duration? duration;
double volume;
RepeatMode repeatMode;  // off, one, all
bool shuffleEnabled;
List<Song> queue;
int? currentIndex;
bool isLoading;
String? errorMessage;
```

**Acciones:**

- `playSong(Song)` — Reproduce una canción
- `pause()` / `resume()` — Pausa/reanuda
- `seekTo(Duration)` — Salta a posición
- `skipNext()` / `skipPrevious()` — Siguiente/anterior
- `setVolume(double)` — Ajusta volumen (0.0-1.0)
- `setQueue(List<Song>)` — Establece cola
- `toggleShuffle()` / `toggleRepeat()` — Cambia modos

#### 🔐 `AuthProvider`

**Estado gestionado:**

```dart
enum AuthStatus { unknown, authenticated, unauthenticated }

AuthStatus status;
User? currentUser;
bool isLoading;
String? errorMessage;
```

**Acciones:**

- `login(email, password)` — Inicia sesión
- `loginWithGoogle()` — Login con Google
- `register(username, email, password)` — Registra usuario
- `logout()` — Cierra sesión
- `updateProfile(User)` — Actualiza perfil
- `changePassword(current, new)` — Cambia contraseña

#### 📚 `LibraryProvider`

**Estado gestionado:**

```dart
List<Song> songs;
List<Album> albums;
List<Artist> artists;
List<Playlist> playlists;
bool isLoading;
bool permissionsGranted;
String? errorMessage;
String searchQuery;
List<Song> searchResults;
```

**Acciones:**

- `loadLibrary()` — Carga biblioteca completa
- `searchSongs(query)` — Busca canciones
- `createPlaylist(name)` — Crea playlist
- `addToPlaylist(playlistId, song)` — Agrega a playlist
- `deletePlaylist(playlistId)` — Elimina playlist
- `requestPermissions()` — Solicita permisos

#### 🌐 `ServerProvider`

**Estado gestionado:**

```dart
ServerSession? activeSession;
List<String> connectedClients;
bool isStarting;
bool isRunning;
String? errorMessage;
bool ngrokEnabled;
String? ngrokUrl;
```

**Acciones:**

- `startServer({ngrok})` — Inicia servidor
- `stopServer()` — Detiene servidor
- `broadcastState(state)` — Difunde estado
- `enableNgrok()` — Activa túnel público

#### 💖 `FavoritesProvider`

**Estado gestionado:**

```dart
List<Song> favorites;
bool isLoading;
String? errorMessage;
Map<String, bool> _cache;  // songId → isFavorite
```

**Acciones:**

- `loadFavorites(userId)` — Carga favoritos
- `addFavorite(userId, song)` — Agrega a favoritos
- `removeFavorite(userId, songId)` — Elimina de favoritos
- `toggleFavorite(userId, song)` — Alterna estado
- `isFavorite(songId)` → `bool` — Verifica (caché)
- `searchFavorites(query)` — Busca en favoritos
- `cleanInvalid(userId)` — Limpia favoritos inválidos

#### ⚙️ `SettingsProvider`

**Estado gestionado:**

```dart
bool darkMode;
Locale locale;
double defaultVolume;
bool autoplay;
AudioQuality quality;
bool downloadOnWifi;
bool showLyrics;
```

**Acciones:**

- `toggleDarkMode()`
- `setLocale(Locale)`
- `updateSettings(Map)`

### 🪝 Hooks Personalizados (`presentation/hooks/`)

**Flutter Hooks** que encapsulan acceso a providers y exponen API simplificada.

#### 🎵 `useAudio()`

```dart
class AudioHook extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final audio = useAudio();

    return Column(
      children: [
        Text(audio.currentSong?.title ?? 'Sin reproducción'),
        IconButton(
          icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: audio.isPlaying ? audio.pause : audio.resume,
        ),
        Slider(
          value: audio.position.inSeconds.toDouble(),
          max: audio.duration?.inSeconds.toDouble() ?? 1.0,
          onChanged: (value) => audio.seekTo(Duration(seconds: value.toInt())),
        ),
      ],
    );
  }
}
```

**Retorna:**

```dart
{
  currentSong, isPlaying, position, duration, volume, queue,
  playSong, pause, resume, seekTo, skipNext, skipPrevious,
  setVolume, toggleShuffle, toggleRepeat
}
```

#### 📚 `useLibrary()`

```dart
final library = useLibrary();
library.songs;           // Lista de canciones
library.loadLibrary();   // Recarga biblioteca
library.searchSongs('rock');  // Busca canciones
```

#### 🌐 `useServer()`

```dart
final server = useServer();
server.startServer();    // Inicia servidor
server.activeSession;    // Sesión activa
server.connectedClients; // Clientes conectados
```

#### 💳 `useSubscription(userId)`

```dart
final subscription = useSubscription(userId);
subscription.currentPlan;       // Plan actual
subscription.isLoading;         // Estado de carga
subscription.upgradePlan(PlanType.premium, PaymentMethod.creditCard);
```

### 🧩 Componentes Reutilizables (`presentation/components/`)

#### 🎵 `PlayerBar`

**Ubicación:** Parte inferior de todas las pantallas (excepto PlayerPage)

**Características:**

- Artwork pequeño de la canción actual
- Título y artista
- Botones: Play/Pausa, Siguiente
- Barra de progreso interactiva
- Al tocar, navega a `PlayerPage`
- Animación de aparición/desaparición

```dart
PlayerBar(
  currentSong: song,
  isPlaying: true,
  position: Duration(seconds: 45),
  duration: Duration(seconds: 180),
  onPlayPause: () => audioProvider.togglePlayPause(),
  onNext: () => audioProvider.skipNext(),
  onTap: () => Navigator.pushNamed(context, '/player'),
)
```

#### 🎼 `SongTile`

**Componente:** Item de lista de canción

**Elementos:**

- Artwork (QueryArtworkWidget de on_audio_query)
- Título de la canción
- Artista y álbum
- Duración formateada
- Indicador de reproducción activa (animación)
- Botón de favorito animado
- Menú contextual (agregar a playlist, compartir, etc.)

```dart
SongTile(
  song: song,
  isPlaying: currentSong?.id == song.id,
  isFavorite: favoritesProvider.isFavorite(song.id),
  onTap: () => audioProvider.playSong(song),
  onFavoriteToggle: () => favoritesProvider.toggleFavorite(userId, song),
)
```

#### 💖 `FavoriteButton`

**Componente:** Botón animado de favorito con soporte de estados

**Características:**

- ✅ Animación de escala al hacer clic
- ✅ Cambio de color: gris → rosa/rojo
- ✅ Animación de "latido" al añadir
- ✅ Feedback háptico
- ✅ Estados: normal, favorito, cargando, error
- ✅ Personalizable (color, tamaño, fondo)

```dart
FavoriteButton(
  song: song,
  userId: userId,
  size: 24,
  favoriteColor: Color(0xFFFF4D8B),
  normalColor: Colors.grey,
  showBackground: true,
  onChanged: (isFavorite) {
    print('Favorito: $isFavorite');
  },
)
```

#### 🔒 `FeatureGuard`

**Componente:** Bloquea características premium según plan de suscripción

**Funcionamiento:**

- Si el usuario tiene acceso, muestra el `child`
- Si no tiene acceso, muestra un overlay bloqueado con:
  - Icono de candado
  - Mensaje explicativo
  - Botón "Actualizar Plan"
  - Blur sobre el contenido

```dart
FeatureGuard(
  userId: userId,
  featureName: 'offline_mode',  // 'quality_selection', 'lossless_quality', etc.
  featureDisplayName: 'Descargas y Modo Sin Conexión',
  child: OfflineModeWidget(),
)
```

**Características bloqueables:**

- `offline_mode` — Descargas y reproducción offline
- `quality_selection` — Selección de calidad de audio
- `playlist_sharing` — Compartir playlists
- `advanced_search` — Búsqueda avanzada
- `lossless_quality` — Calidad sin pérdida
- `family_sharing` — Compartir con familia

#### 💳 `PaymentFormDialog`

**Componente:** Diálogo modal para procesar pagos

**Métodos de pago:**

1. **Tarjeta de Crédito/Débito**
   - Número de tarjeta (validación Luhn)
   - Fecha de expiración (MM/YY)
   - CVV (3-4 dígitos)
   - Nombre en tarjeta

2. **PayPal**
   - Email de PayPal
   - Redirección automática

3. **Tarjeta de Débito**
   - Mismo formulario que crédito

```dart
PaymentFormDialog(
  amount: 5.0,
  currency: 'USD',
  planName: 'Premium',
  onPaymentComplete: (success, transactionId) {
    if (success) {
      // Actualizar suscripción
    }
  },
)
```

#### 📲 `QRWidget`

**Componente:** Panel de código QR con información del servidor

**Elementos:**

- Código QR grande
- URL del servidor
- Contador de clientes conectados
- Estado del servidor (running/stopped)
- Botón para copiar URL
- Indicador de túnel ngrok activo (si aplica)

```dart
QRWidget(
  payload: '{"type":"airpulse_connect","url":"..."}',
  serverUrl: 'http://192.168.1.100:8765',
  connectedClients: 3,
  isRunning: true,
  ngrokUrl: 'https://abc123.ngrok-free.app',
)
```

#### 🖼️ `SongArtwork`

**Componente:** Widget de artwork con fallback

**Características:**

- Carga artwork desde ruta local
- Placeholder animado mientras carga
- Fallback a icono de música si no hay artwork
- Caché automático
- Esquinas redondeadas personalizables
- Efecto shimmer en carga

```dart
SongArtwork(
  song: song,
  size: 200,
  borderRadius: 12,
  placeholder: shimmerPlaceholder,
)
```

### 🎨 Widgets Específicos (`presentation/widgets/`)

#### 📤 `ShareOptionsDialog`

**Componente:** Diálogo con opciones de compartir canciones

**Opciones:**

1. 📡 **Nearby Share** — Bluetooth/WiFi Direct
2. 📋 **Copiar Link** — Copia URL de streaming
3. 📱 **Compartir Info** — Share sheet nativo
4. 📧 **Email** — Compartir via email
5. 💬 **Redes Sociales** — WhatsApp, Telegram, etc.

```dart
ShareOptionsDialog(
  song: song,
  serverUrl: 'http://192.168.1.100:8765',
  onNearbyShare: () {
    // Iniciar Nearby Share
  },
  onCopyLink: () {
    // Copiar al portapapeles
  },
)
```

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

---

## 📄 Todas las Páginas de la Aplicación

### 📚 `LibraryPage` — Pantalla Principal

**Ruta:** `/`

**Tabs:**

- **Canciones:** Lista completa con scroll infinito, indicador de canción activa
- **Álbumes:** Grid 2x con artwork, contador de canciones
- **Artistas:** Lista con avatar, contador de canciones y álbumes

**Features:**

- ✅ Búsqueda en tiempo real (título, artista, álbum)
- ✅ Pull-to-refresh
- ✅ FAB para crear playlist
- ✅ PlayerBar integrado (fixed bottom)
- ✅ Botones AppBar: Favoritos, Servidor, Perfil, Settings
- ✅ Empty state con permisos no otorgados

### 🎵 `PlayerPage` — Reproductor Completo

**Ruta:** `/player`

**Secciones:**

1. **Artwork grande** (300x300, con gradient adaptativo)
2. **Metadata:** Título, artista, álbum
3. **Controles:**
   - Shuffle (🔀)
   - Previous (⏮️)
   - Play/Pause (⏯️) grande central
   - Next (⏭️)
   - Repeat (🔁)
4. **Progreso:** Barra interactiva + tiempos
5. **Volumen:** Slider horizontal
6. **Tabs inferiores:**
   - **Letras:** Sincronizadas (.lrc) con auto-scroll
   - **Cola:** Reordenable con drag & drop
   - **Info:** Metadata técnica completa

**Gestos:**

- Swipe down para cerrar
- Swipe left/right para next/previous
- Tap en artwork para expand/collapse controles

### 🌐 `ServerPage` — Gestión del Servidor

**Ruta:** `/server`

**Secciones:**

#### Control del Servidor

```bash
Estado: [●] Ejecutando
IP: 192.168.1.100:8765
[Detener Servidor]
☑ Habilitar Ngrok (túnel público)
```

#### Código QR

- QR grande (300x300)
- Botón "Copiar URL"
- Botón "Compartir QR"

#### Clientes Conectados (3)

```bash
┌─────────────────────────────┐
│ 📱 Chrome (192.168.1.105)   │ [X]
│ 💻 Firefox (192.168.1.110)  │ [X]
│ 📱 Safari (192.168.1.115)   │ [X]
└─────────────────────────────┘
```

#### Estadísticas

- Tiempo de actividad
- Datos transferidos
- Solicitudes atendidas

#### Escanear QR (Solo Móvil)

- [Escanear QR para conectar a otro servidor]

### 🔐 `LoginPage` — Inicio de Sesión

**Ruta:** `/login`

**Campos:**

```bash
Email:    [________________]
Password: [________________] [👁]

[Iniciar Sesión]

──────── O ────────

[🔵 Continuar con Google]

¿No tienes cuenta? [Regístrate]
¿Olvidaste tu contraseña? [Recuperar]
```

**Modo Web adicional:**

- Campo: "URL del Servidor" (opcional)
- Autocompletar si viene de `?serverUrl=`

### 📝 `RegisterPage` — Registro

**Ruta:** `/register`

**Validaciones:**

- Username: 3-20 caracteres
- Email: formato válido
- Password: 8+ caracteres, mayúscula, número, carácter especial
- Indicador de fortaleza con barras de colores

### 💖 `FavoritesPage` — Favoritos

**Ruta:** `/favorites`

**Features:**

- ✅ Lista ordenada por fecha añadido (desc)
- ✅ Búsqueda integrada
- ✅ [▶ Reproducir Todo] con shuffle opcional
- ✅ Swipe para eliminar
- ✅ [🧹 Limpiar Inválidos] — elimina favoritos con archivos borrados
- ✅ Estadísticas: `89 favoritos • 342 MB • 4h 32m`

**Empty State:**

```bash
      💔
  Sin favoritos aún
  Toca 💖 en cualquier canción
```

### 💿 `AlbumDetailPage` — Detalle de Álbum

**Ruta:** `/album/:id`

**Layout:**

- Hero animation desde grid
- Artwork 250x250
- Info: artista, año, canciones, duración total
- [▶ Reproducir Todo] [💖] [•••]
- Lista de tracks numerados

### 🎤 `ArtistDetailPage` — Detalle de Artista

**Ruta:** `/artist/:id`

**Secciones:**

- Foto del artista (si está disponible)
- Nombre y estadísticas
- [▶ Reproducir Todo]
- **Canciones Populares** (top 5)
- **Álbumes** (grid horizontal scrolleable)
- **Información** (si está disponible)

### 💎 `PricingPage` — Planes de Suscripción

**Ruta:** `/pricing`

**Comparación de planes:**

| Feature             |   Free   | Starter  |  Pro  | Premium ⭐  | Elite |
| ------------------- | :------: | :------: | :---: | :---------: | :---: |
| **Precio**          |    $0    |    $1    |  $3   |     $5      |  $10  |
| Anuncios            |    ❌    |    ✅    |  ✅   |     ✅      |  ✅   |
| Offline             |    ❌    |    ✅    |  ✅   |     ✅      |  ✅   |
| Calidad             | Standard | Standard |  HD   |  Lossless   | Hi-Fi |
| Almacenamiento      |   1GB    |   5GB    | 25GB  |    50GB     | 200GB |
| Compartir Playlists |    ❌    |    ❌    |  ✅   |     ✅      |  ✅   |
| Búsqueda Avanzada   |    ❌    |    ❌    |  ❌   |     ✅      |  ✅   |
| Estadísticas        |    ❌    |    ❌    |  ❌   |     ✅      |  ✅   |
| Ecualizador         |    ❌    |    ❌    |  ❌   |     ✅      |  ✅   |
| Dolby Atmos         |    ❌    |    ❌    |  ❌   |     ❌      |  ✅   |
| Familia (5 cuentas) |    ❌    |    ❌    |  ❌   |     ❌      |  ✅   |
| Soporte             |  Email   |  Email   | Email | Prioritario | 24/7  |

**Funcionalidades:**

- ✅ Plan actual destacado
- ✅ Badge "Recomendado" en Premium
- ✅ Al seleccionar, abre `PaymentFormDialog`
- ✅ Confirmación antes de downgrade
- ✅ Muestra fecha de próximo cobro
- ✅ Historial de transacciones

### 👤 `ProfilePage` — Perfil

**Ruta:** `/profile`

**Secciones:**

#### Información Personal

- Avatar (tappable para cambiar)
- Nombre completo
- Username
- Email
- Plan actual con badge

#### Estadísticas

```bash
🎵 1,234 canciones reproducidas
💖 89 favoritos
📝 12 playlists
⏱️ 156h de reproducción
📊 Plan: Premium 💎
```

#### Opciones

- ✏️ Editar Perfil
- 🔑 Cambiar Contraseña
- 💎 Actualizar Plan
- ⚙️ Configuración
- 📊 Mis Estadísticas
- 📜 Política de Privacidad
- 📜 Términos y Condiciones
- ©️ Propiedad Intelectual
- 🚪 Cerrar Sesión

### ✏️ `EditProfilePage` — Editar Perfil

**Ruta:** `/profile/edit`

**Campos editables:**

- 📷 Avatar (galería/cámara)
- Username
- First Name
- Last Name
- Email (requiere reautenticación)
- Bio (opcional)

### 🔑 `ChangePasswordPage` — Cambiar Contraseña

**Ruta:** `/profile/change-password`

**Validaciones:**

- Password actual correcto
- Nueva contraseña cumple requisitos
- Confirmación coincide
- Indicador de fortaleza

### ⚙️ `SettingsPage` — Configuración

**Ruta:** `/settings`

#### 🎨 Apariencia

- **Tema:** Sistema / Claro / Oscuro
- **Idioma:** Español / English
- **Color Primario:** Selector de color
- **Tamaño de texto:** Small / Medium / Large
- **Animaciones:** On / Off

#### 🎵 Audio

- **Calidad predeterminada:** Low (128kbps) / Medium (192kbps) / High (320kbps) / Lossless (FLAC)
- **Volumen inicial:** Slider 0-100%
- **Crossfade:** 0-12 segundos
- **Normalización de volumen:** On / Off
- **Ecualizador:** Off / Rock / Pop / Jazz / Classical / Bass Boost / Custom

#### 📱 Descarga y Offline

- **Descargar solo en WiFi:** On / Off
- **Calidad de descarga:** Same as streaming / High / Lossless
- **Ubicación:** Internal / SD Card
- **Liberar caché:** [Limpiar ahora] (342 MB)

#### 🌐 Servidor

- **Puerto:** 8765 (editable)
- **Habilitar ngrok por defecto:** On / Off
- **Requerir contraseña:** On / Off
- **Contraseña del servidor:** [________]

#### 🔔 Notificaciones

- **Notificación de media:** On / Off
- **Control desde lockscreen:** On / Off
- **Control desde auriculares:** On / Off
- **Vibración al cambiar canción:** On / Off

#### 🛡️ Privacidad

- **Enviar datos de uso:** On / Off
- **Analytics:** On / Off
- **Crash reports:** On / Off
- **Mostrar actividad a amigos:** On / Off

#### 💾 Datos

- **Descargar covers automáticamente:** On / Off
- **Calidad de covers:** Low / Medium / High
- **Caché de metadata:** [Limpiar] (45 MB)

### 📡 `NearbySharePage` — Compartir P2P

**Ruta:** `/nearby-share`

**Dos modos:**

#### 📤 Enviar (Advertiser)

```bash
Compartiendo como: John Doe
Dispositivo visible como: "John's Phone"

Esperando conexiones...
[●●●] Escaneando...

[Cancelar]
```

#### 📥 Recibir (Discoverer)

```bash
Dispositivos Cercanos:

┌─────────────────────────────┐
│ 📱 John's Phone             │ [Conectar]
│ 📱 Jane's Tablet            │ [Conectar]
│ 💻 Mike's Laptop            │ [Conectar]
└─────────────────────────────┘

[Actualizar]
```

**Progreso de Transferencia:**

```bash
Enviando a: Jane's Tablet
🎵 Never Gonna Give You Up

━━━━━━━━━━◉━━━━━━━━━━━━━
45% • 2.1 MB / 4.7 MB

Tiempo restante: ~30 segundos

[Cancelar]
```

### 🔐 `GoogleOnboardingPage` — Onboarding Google

**Ruta:** `/google-onboarding`

**Pantallas:**

1. **Bienvenida:** "¡Hola, [Nombre]!"
2. **Permisos:** Solicitar permisos necesarios
3. **Tour:** Características principales (swiper)
4. **Configuración inicial:** Preferencias básicas

### 🌐 `WebLibraryPage` — Biblioteca Web

**Solo para navegador**
**Ruta:** `/web`

**Layout desktop:**

```bash
┌──────────────────────────────────────────────────────────┐
│ 🎵 AirPulse Web    [Search...]    john@example.com  [⚙️] │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Canciones (1,234)                     [🔀] [🔁]         │
│ ┌────────────────────────────────────────────────────┐  │
│ │ # Title                 Artist        Album    Time│  │
│ │ 1 Never Gonna Give...   Rick Astley   WYNYS   3:32│  │
│ │ 2 Together Forever      Rick Astley   WYNYS   3:22│  │
│ │ ...                                               │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
├──────────────────────────────────────────────────────────┤
│ ♪ Never Gonna Give You Up - Rick Astley                 │
│ ━━━━━━━━━━━━━━━◉━━━━━━━━━━━━━━━━━━━━  1:45 / 3:32      │
│ [🔀] [⏮] [⏯] [⏭] [🔁]    🔊 ━━━━━◉━━━━━              │
└──────────────────────────────────────────────────────────┘
```

**Features:**

- ✅ Conecta via HTTP + WebSocket
- ✅ Reconexión automática (exponential backoff)
- ✅ Reproduce con `<audio>` HTML5
- ✅ Keyboard shortcuts:
  - `Space`: Play/Pause
  - `←/→`: Seek -5s/+5s
  - `↑/↓`: Volume
  - `N`: Next
  - `P`: Previous
  - `/`: Focus search

### 🌐 `ServerWebViewPage` — WebView

**Ruta:** `/server-webview`

- WebView completo de la web app del servidor
- Controles: Back, Forward, Reload
- Loading indicator
- Error handling

### 📜 `PrivacyPolicyPage`

**Ruta:** `/privacy-policy`

Texto completo de la política de privacidad con secciones:

- Recopilación de datos
- Uso de datos
- Compartir datos
- Seguridad
- Derechos del usuario
- Cookies
- Cambios en la política

### 📜 `TermsPage`

**Ruta:** `/terms`

Términos y condiciones completos:

- Aceptación de términos
- Licencia de uso
- Restricciones
- Propiedad intelectual
- Responsabilidad
- Modificaciones
- Jurisdicción

### ©️ `IntellectualPropertyPage`

**Ruta:** `/intellectual-property`

- Derechos de autor de AirPulse
- Licencias de software de terceros
- Atribuciones de iconos y recursos
- Flutter y Dart license
- Open source licenses

---

## 🔥 Configuración de Firebase

### Servicios Utilizados

#### 🔐 Firebase Authentication

**Métodos habilitados:**

- Email/Password
- Google Sign-In

**Configuración en Firebase Console:**

```bash
Authentication > Sign-in method > Enable:
✅ Email/Password
✅ Google
```

**OAuth Client ID (Google):**

- Android: Configurado en `google-services.json`
- iOS: Configurado en `GoogleService-Info.plist`
- Web: Configurado en Firebase Console

#### 🗄️ Firebase Realtime Database

**Estructura de datos:**

```json
{
  "users": {
    "{userId}": {
      "username": "john_doe",
      "email": "john@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "avatarPath": "...",
      "createdAt": "2024-01-01T00:00:00Z",
      "lastLogin": "2024-05-16T10:30:00Z"
    }
  },
  "web_sessions": {
    "{sessionId}": {
      "status": "pending|approved|expired",
      "createdAt": 1234567890,
      "expiresAt": 1234567890,
      "uid": "...",
      "email": "...",
      "username": "...",
      "serverUrl": "..."
    }
  }
}
```

**Reglas de seguridad:**

```json
{
  "rules": {
    "users": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    },
    "web_sessions": {
      "$sessionId": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

#### 📊 Firebase Analytics (Opcional)

- Eventos personalizados
- Seguimiento de conversiones
- Análisis de uso

#### ☁️ Firebase Storage (Preparado)

- Avatares de usuario
- Artwork personalizado
- Archivos compartidos

### Configuración Multiplataforma

#### Android (`android/app/google-services.json`)

```json
{
  "project_info": {
    "project_id": "airpulse-xxxxx",
    "project_number": "123456789012"
  },
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "corman.air.pulse.airpulse"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSyXXXXXXXXXXXXXXXXXXXXX"
        }
      ]
    }
  ]
}
```

#### iOS (`ios/Runner/GoogleService-Info.plist`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>AIzaSyXXXXXXXXXXXXXXXXXXXXX</string>
  <key>GCM_SENDER_ID</key>
  <string>123456789012</string>
  <key>BUNDLE_ID</key>
  <string>corman.air.pulse.airpulse</string>
  ...
</dict>
</plist>
```

#### Web

- Configuración en `index.html` con Firebase SDK
- Credenciales desde `env.txt` via `EnvLoader`

---

## 📱 Configuración de Android

### `android/app/build.gradle.kts`

**Características destacadas:**

- ✅ **compileSdk:** Latest (Android 14+)
- ✅ **minSdk:** 23 (Android 6.0)
- ✅ **targetSdk:** Latest
- ✅ **NDK:** 27.0.12077973
- ✅ **Java 17** target
- ✅ **Kotlin** 1.9+
- ✅ **Google Services** plugin
- ✅ **Ngrok Java:** `com.ngrok:ngrok-java:1.1.1`
- ✅ **Packaging:** Evita conflictos de `.so`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "corman.air.pulse.airpulse"
    compileSdk = 34

    defaultConfig {
        applicationId = "corman.air.pulse.airpulse"
        minSdk = 23
        targetSdk = 34
    }

    packaging {
        jniLibs {
            pickFirsts += listOf("**/libngrok_java.so")
        }
    }
}

dependencies {
    implementation("com.ngrok:ngrok-java:1.1.1")
    runtimeOnly("com.ngrok:ngrok-java-native:1.1.1:linux-android-aarch_64")
}
```

### `AndroidManifest.xml`

**Permisos:**

```xml
<!-- Internet y Red -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

<!-- Almacenamiento -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- Nearby Connections -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>

<!-- Audio en segundo plano -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- Otros -->
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**Services:**

```xml
<application>
    ...
    <!-- Audio Service -->
    <service
        android:name="com.ryanheise.audioservice.AudioService"
        android:foregroundServiceType="mediaPlayback"
        android:exported="true">
        <intent-filter>
            <action android:name="android.media.browse.MediaBrowserService"/>
        </intent-filter>
    </service>

    <!-- Metadata -->
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version"/>
</application>
```

### MethodChannels Nativos

#### 🌍 Ngrok Channel (`com.airpulse/ngrok`)

```kotlin
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor, "com.airpulse/ngrok")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTunnel" -> startNgrokTunnel(call, result)
                    "stopTunnel" -> stopNgrokTunnel(result)
                }
            }
    }
}
```

#### 🔊 Volume Channel (`com.airpulse/volume`)

```kotlin
class VolumeObserver(private val channel: MethodChannel) : ContentObserver(Handler(Looper.getMainLooper())) {
    override fun onChange(selfChange: Boolean) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val volumeLevel = currentVolume.toDouble() / maxVolume
        channel.invokeMethod("onVolumeChanged", volumeLevel)
    }
}
```

---

## 📦 Dependencias Completas

### Audio y Multimedia

| Package                 | Versión  | Uso                                   |
| ----------------------- | -------- | ------------------------------------- |
| `just_audio`            | ^0.9.43  | Motor de reproducción de audio        |
| `audio_service`         | ^0.18.16 | Audio en segundo plano                |
| `audio_session`         | ^0.1.21  | Gestión de sesión de audio            |
| `on_audio_query`        | ^2.9.0   | Consulta de biblioteca de audio local |
| `audio_metadata_reader` | ^1.4.1   | Lectura de metadata de archivos       |

### Servidor y Red

| Package              | Versión | Uso                    |
| -------------------- | ------- | ---------------------- |
| `shelf`              | ^1.4.2  | Servidor HTTP          |
| `shelf_router`       | ^1.1.4  | Enrutamiento HTTP      |
| `shelf_web_socket`   | ^2.0.0  | WebSocket sobre Shelf  |
| `web_socket_channel` | ^3.0.1  | Cliente WebSocket      |
| `http`               | ^1.2.2  | Cliente HTTP           |
| `connectivity_plus`  | ^6.1.3  | Estado de conectividad |
| `network_info_plus`  | ^6.0.1  | Información de red     |

### QR y Compartir

| Package              | Versión | Uso                       |
| -------------------- | ------- | ------------------------- |
| `qr_flutter`         | ^4.1.0  | Generación de códigos QR  |
| `mobile_scanner`     | ^5.2.3  | Escaneo de códigos QR     |
| `nearby_connections` | ^4.1.1  | P2P Bluetooth/WiFi Direct |
| `share_plus`         | ^10.1.4 | Share sheet nativo        |

### State Management

| Package         | Versión | Uso                  |
| --------------- | ------- | -------------------- |
| `provider`      | ^6.1.2  | Provider pattern     |
| `flutter_hooks` | ^0.20.5 | Hooks personalizados |
| `flutter_redux` | ^0.10.0 | Redux (uso parcial)  |
| `redux`         | ^5.0.0  | Redux core           |
| `rxdart`        | ^0.28.0 | Streams reactivos    |

### Firebase

| Package             | Versión | Uso               |
| ------------------- | ------- | ----------------- |
| `firebase_core`     | ^3.13.0 | Core de Firebase  |
| `firebase_auth`     | ^5.5.2  | Autenticación     |
| `firebase_database` | ^11.3.4 | Realtime Database |
| `google_sign_in`    | ^6.2.2  | Google Sign-In    |

### Almacenamiento

| Package                 | Versión | Uso                  |
| ----------------------- | ------- | -------------------- |
| `sqflite`               | ^2.4.1  | Base de datos SQLite |
| `shared_preferences`    | ^2.3.4  | Key-value store      |
| `path_provider`         | ^2.1.5  | Rutas del sistema    |
| `flutter_cache_manager` | ^3.4.1  | Gestión de caché     |

### UI y Utilidades

| Package              | Versión | Uso                  |
| -------------------- | ------- | -------------------- |
| `cupertino_icons`    | ^1.0.8  | Iconos de iOS        |
| `intl`               | ^0.19.0 | Internacionalización |
| `uuid`               | ^4.5.1  | Generación de UUIDs  |
| `equatable`          | ^2.0.7  | Igualdad de objetos  |
| `file_picker`        | ^8.1.4  | Selector de archivos |
| `url_launcher`       | ^6.3.1  | Abrir URLs           |
| `webview_flutter`    | ^4.13.1 | WebView              |
| `permission_handler` | ^11.3.1 | Gestión de permisos  |
| `mime`               | ^2.0.0  | Tipos MIME           |

### Dependencias de Desarrollo

| Package             | Versión | Uso                  |
| ------------------- | ------- | -------------------- |
| `flutter_lints`     | ^5.0.0  | Linting              |
| `build_runner`      | ^2.4.14 | Generación de código |
| `freezed`           | ^2.5.8  | Clases inmutables    |
| `json_serializable` | ^6.9.2  | JSON serialization   |

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK 3.8.1 o superior
- Dart SDK 3.8.1 o superior
- Android Studio / VS Code
- Xcode (para iOS/macOS)
- Cuenta de Firebase
- Authtoken de Ngrok (opcional)

### 1. Clonar el repositorio

```bash
git clone https://github.com/18-anth/AirPulse.git
cd airpulse
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

#### Crear proyecto en Firebase Console

1. Ir a <https://console.firebase.google.com>
2. Crear nuevo proyecto: "AirPulse"
3. Habilitar Google Analytics (opcional)

#### Habilitar servicios

```bash
Authentication > Sign-in method:
✅ Email/Password
✅ Google

Realtime Database > Create database:
✅ Start in test mode (luego ajustar reglas)
```

#### Descargar archivos de configuración

- Android: `google-services.json` → `android/app/`
- iOS: `GoogleService-Info.plist` → `ios/Runner/`
- Web: Copiar config a `assets/env.txt`

### 4. Configurar `assets/env.txt`

```env
API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXX
AUTH_DOMAIN=airpulse-xxxxx.firebaseapp.com
DATABASE_URL=https://airpulse-xxxxx.firebaseio.com
PROJECT_ID=airpulse-xxxxx
STORAGE_BUCKET=airpulse-xxxxx.appspot.com
MESSAGING_SENDER_ID=123456789012
APP_ID=1:123456789012:web:abcdef123456
ANDROID_APP_ID=1:123456789012:android:abcdef123456
IOS_APP_ID=1:123456789012:ios:abcdef123456
MEASUREMENT_ID=G-XXXXXXXXXX
NGROK_AUTHTOKEN=3DNRmnh96kv1pNGMOQ0vOLNlyQL_3Br7DyYiLyGJQe8BNJij2
```

### 5. Ejecutar la aplicación

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome --web-port 3000

# macOS
flutter run -d macos

# Modo Release
flutter run --release
```

### 6. Build para producción

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# macOS
flutter build macos --release
```

---

## 📖 Documentación Adicional

En el repositorio encontrarás guías detalladas:

- **[FAVORITES_SYSTEM_GUIDE.md](FAVORITES_SYSTEM_GUIDE.md)** — Sistema completo de favoritos con SQLite
- **[SUBSCRIPTION_SYSTEM.md](SUBSCRIPTION_SYSTEM.md)** — Sistema de suscripciones y pagos
- **[SUBSCRIPTION_QUICK_START.md](SUBSCRIPTION_QUICK_START.md)** — Guía rápida de suscripciones
- **[QUICK_START_FAVORITES.md](QUICK_START_FAVORITES.md)** — Integración rápida de favoritos
- **[SECURITY.md](SECURITY.md)** — Política de seguridad y reporte de vulnerabilidades

---

## 🎯 Características Destacadas

### ✨ Funcionalidades Únicas

#### 🌐 Servidor HTTP/WebSocket Embebido

- Primera app de música con servidor HTTP completamente funcional en móvil
- Streaming de audio a navegadores sin backend externo
- WebSocket bidireccional para sincronización en tiempo real

#### 📡 Compartir P2P con Nearby Connections

- Transferencia de canciones sin Internet
- Bluetooth + WiFi Direct simultáneos
- Progreso en tiempo real

#### 🌍 Túneles Públicos con Ngrok

- Acceso a tu biblioteca desde cualquier lugar del mundo
- HTTPS seguro automático
- Sin configuración de firewall

#### 🔐 Sesiones QR estilo WhatsApp Web

- Login sin contraseña desde navegador
- Escaneo QR en móvil para aprobar
- Sesiones temporales con expiración automática

#### 💖 Sistema de Favoritos Enterprise-Grade

- SQLite con optimizaciones avanzadas
- Índices para queries rápidas
- Validación automática de archivos
- 10 casos de uso especializados

#### 💳 Sistema de Suscripciones Completo

- 5 planes con características granulares
- Múltiples métodos de pago
- Bloqueo inteligente de características
- Historial de transacciones

#### 🎵 Audio Background Profesional

- Notificaciones de media con controles
- Integración con lockscreen
- Soporte para Android Auto y CarPlay
- Control desde auriculares Bluetooth

#### 📊 Arquitectura Clean

- Separación estricta de capas
- Testeable y mantenible
- Inyección de dependencias con GetIt
- Casos de uso específicos

### 🔒 Seguridad

- ✅ Autenticación con Firebase
- ✅ Variables de entorno encriptadas
- ✅ Sesiones con expiración
- ✅ Validación de entrada en todos los formularios
- ✅ CORS configurado correctamente
- ✅ Sanitización de archivos de audio
- ✅ Rate limiting en servidor
- ✅ HTTPS obligatorio para túneles

### 🌍 Internacionalización

- ✅ Español (es)
- ✅ Inglés (en)
- 🔜 Más idiomas próximamente

### 📱 Plataformas Soportadas

| Plataforma | Estado          | Características           |
| ---------- | --------------- | ------------------------- |
| Android    | ✅ Completo     | Todas las características |
| iOS        | ✅ Completo     | Todas menos Ngrok         |
| Web        | ✅ Completo     | Cliente solamente         |
| macOS      | ✅ Completo     | Todas menos Ngrok         |
| Windows    | 🔜 Próximamente | En desarrollo             |
| Linux      | 🔜 Próximamente | En desarrollo             |

---

## 🐛 Solución de Problemas

### Error: "No se encuentran canciones"

**Causa:** Permisos no otorgados o no hay archivos de audio
**Solución:**

1. Verificar permisos en Settings > Apps > AirPulse > Permissions
2. Asegurarse de tener archivos MP3/FLAC/AAC en el dispositivo
3. Reiniciar la app

### Error: "No se puede iniciar el servidor"

**Causa:** Puerto 8765 ocupado o permisos de red
**Solución:**

1. Verificar que no haya otra instancia corriendo
2. Cambiar puerto en Settings
3. Verificar firewall

### Error: "Ngrok no se pudo iniciar"

**Causa:** Token inválido o problema de red
**Solución:**

1. Verificar authtoken en `env.txt`
2. Verificar conexión a Internet
3. Solo funciona en Android

### Error: "No se puede conectar al servidor desde navegador"

**Causa:** No están en la misma red WiFi
**Solución:**

1. Verificar que ambos dispositivos están en la misma red
2. Usar ngrok si están en redes diferentes
3. Verificar firewall del router

### Error: "Favoritos no se guardan"

**Causa:** Error al inicializar SQLite
**Solución:**

1. Limpiar caché de la app
2. Reinstalar la app
3. Verificar permisos de almacenamiento

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el repositorio
2. Crear una rama feature (`git checkout -b feature/amazing-feature`)
3. Commit cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abrir un Pull Request

### Guías de Contribución

- Seguir Clean Architecture
- Tests para nuevas características
- Documentar código complejo
- Actualizar README si es necesario

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

### **Anthony Estuardo**

- GitHub: [@18-anth](https://github.com/18-anth)
- Email: [anthony@airpulse.app](mailto:anthony@airpulse.app)

---

## 🙏 Agradecimientos

- Flutter Team por el increíble framework
- Firebase por los servicios backend
- Ngrok por los túneles públicos
- Google Nearby Connections API
- Comunidad de Flutter

---

## 📈 Roadmap

### v1.1.0 (Próximamente)

- [ ] Soporte para Windows y Linux
- [ ] Ecualizador visual
- [ ] Letras automáticas (API de Genius)
- [ ] Recomendaciones con ML
- [ ] Modo Chromecast

### v1.2.0

- [ ] Podcasts
- [ ] Radio por Internet
- [ ] Temas personalizables
- [ ] Widgets para pantalla principal
- [ ] Android Auto completo

### v2.0.0

- [ ] Streaming desde servicios externos (Spotify, Apple Music)
- [ ] Social features (compartir playlists públicas)
- [ ] Modo Party (control colaborativo)
- [ ] Visualizaciones de audio
- [ ] AR lyrics (letras en realidad aumentada)

---

## 📊 Estadísticas del Proyecto

- **Líneas de código:** ~15,000+
- **Archivos Dart:** 80+
- **Paquetes usados:** 45+
- **Pantallas:** 20+
- **Servicios:** 10+
- **Providers:** 6+
- **Use Cases:** 30+
- **Widgets personalizados:** 25+

---

## 🔗 Enlaces Útiles

- [Repositorio en GitHub](https://github.com/18-anth/AirPulse)
- [Web App](https://18-anth.github.io/AirPulseWeb)
- [Documentación de Flutter](https://flutter.dev/docs)
- [Firebase Console](https://console.firebase.google.com)
- [Ngrok Dashboard](https://dashboard.ngrok.com)

---

<div align="center">

### **Hecho con ❤️ usando Flutter**

⭐ Si te gusta este proyecto, danos una estrella en GitHub ⭐

</div>
