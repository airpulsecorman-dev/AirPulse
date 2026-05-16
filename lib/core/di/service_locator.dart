import 'package:get_it/get_it.dart';
import 'package:airpulse/services/audio_service.dart';
import 'package:airpulse/services/audio_handler.dart';
import 'package:airpulse/services/library_service.dart';
import 'package:airpulse/services/local_server_service.dart';
import 'package:airpulse/services/qr_service.dart';
import 'package:airpulse/services/payment_service.dart';
import 'package:airpulse/data/repositories/subscription_repository_impl.dart';
import 'package:airpulse/domain/repositories/subscription_repository.dart';
import 'package:airpulse/domain/usecases/subscription_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dependencias de favoritos
import 'package:airpulse/data/sources/local/favorites_database.dart';
import 'package:airpulse/data/repositories/favorites_repository_impl.dart';
import 'package:airpulse/domain/repositories/favorites_repository.dart';
import 'package:airpulse/domain/usecases/favorites_usecases.dart';

final sl = GetIt.instance;

Future<void> setupDependencies(AirPulseAudioHandler audioHandler) async {
  // El handler ya está inicializado por AudioService.init() en main.dart
  sl.registerSingleton<AirPulseAudioHandler>(audioHandler);
  sl.registerLazySingleton<AudioService>(() => AudioService(audioHandler));
  sl.registerLazySingleton<LibraryService>(() => LibraryService());
  sl.registerLazySingleton<LocalServerService>(() => LocalServerService());
  sl.registerLazySingleton<QRService>(() => QRService());

  // Registrar servicios de suscripción
  await _setupSubscriptionDependencies();

  // Registrar servicios de favoritos
  await _setupFavoritesDependencies();
}

Future<void> _setupSubscriptionDependencies() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Servicios de pago
  sl.registerSingleton<PaymentService>(PaymentService(sl<SharedPreferences>()));

  // Repositorios
  sl.registerSingleton<SubscriptionRepository>(
    SubscriptionRepositoryImpl(
      prefs: sl<SharedPreferences>(),
      paymentService: sl<PaymentService>(),
    ),
  );

  // Casos de uso
  sl.registerSingleton<GetAvailablePlansUseCase>(
    GetAvailablePlansUseCase(sl<SubscriptionRepository>()),
  );
  sl.registerSingleton<GetCurrentSubscriptionUseCase>(
    GetCurrentSubscriptionUseCase(sl<SubscriptionRepository>()),
  );
  sl.registerSingleton<UpgradePlanUseCase>(
    UpgradePlanUseCase(sl<SubscriptionRepository>()),
  );
  sl.registerSingleton<CancelSubscriptionUseCase>(
    CancelSubscriptionUseCase(sl<SubscriptionRepository>()),
  );
  sl.registerSingleton<IsFeatureAvailableUseCase>(
    IsFeatureAvailableUseCase(sl<SubscriptionRepository>()),
  );
  sl.registerSingleton<GetTransactionHistoryUseCase>(
    GetTransactionHistoryUseCase(sl<SubscriptionRepository>()),
  );
}

/// Configura las dependencias del sistema de favoritos
///
/// Inicializa SQLite, repositorio y casos de uso
Future<void> _setupFavoritesDependencies() async {
  // Base de datos SQLite (Singleton)
  sl.registerSingleton<FavoritesDatabase>(FavoritesDatabase.instance);

  // Repositorio de favoritos
  sl.registerSingleton<FavoritesRepository>(
    FavoritesRepositoryImpl(sl<FavoritesDatabase>()),
  );

  // Casos de uso - Básicos
  sl.registerSingleton<GetFavoritesUseCase>(
    GetFavoritesUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<AddFavoriteUseCase>(
    AddFavoriteUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<RemoveFavoriteUseCase>(
    RemoveFavoriteUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<IsFavoriteUseCase>(
    IsFavoriteUseCase(sl<FavoritesRepository>()),
  );

  // Casos de uso - Avanzados
  sl.registerSingleton<ToggleFavoriteUseCase>(
    ToggleFavoriteUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<CleanInvalidFavoritesUseCase>(
    CleanInvalidFavoritesUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<GetFavoritesCountUseCase>(
    GetFavoritesCountUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<SearchFavoritesUseCase>(
    SearchFavoritesUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<ClearAllFavoritesUseCase>(
    ClearAllFavoritesUseCase(sl<FavoritesRepository>()),
  );

  sl.registerSingleton<GetFavoritesStatisticsUseCase>(
    GetFavoritesStatisticsUseCase(sl<FavoritesRepository>()),
  );
}
