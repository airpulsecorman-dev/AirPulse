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
}

Future<void> _setupSubscriptionDependencies() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Servicios de pago
  sl.registerSingleton<PaymentService>(
    PaymentService(sl<SharedPreferences>()),
  );

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
