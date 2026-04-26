import 'package:get_it/get_it.dart';
import 'package:airpulse/services/audio_service.dart';
import 'package:airpulse/services/audio_handler.dart';
import 'package:airpulse/services/library_service.dart';
import 'package:airpulse/services/local_server_service.dart';
import 'package:airpulse/services/qr_service.dart';

final sl = GetIt.instance;

void setupDependencies(AirPulseAudioHandler audioHandler) {
  // El handler ya está inicializado por AudioService.init() en main.dart
  sl.registerSingleton<AirPulseAudioHandler>(audioHandler);
  sl.registerLazySingleton<AudioService>(() => AudioService(audioHandler));
  sl.registerLazySingleton<LibraryService>(() => LibraryService());
  sl.registerLazySingleton<LocalServerService>(() => LocalServerService());
  sl.registerLazySingleton<QRService>(() => QRService());
}
