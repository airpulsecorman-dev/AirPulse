import 'package:get_it/get_it.dart';
import 'package:airpulse/services/audio_service.dart';
import 'package:airpulse/services/library_service.dart';
import 'package:airpulse/services/local_server_service.dart';
import 'package:airpulse/services/qr_service.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Services (singletons)
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<LibraryService>(() => LibraryService());
  sl.registerLazySingleton<LocalServerService>(() => LocalServerService());
  sl.registerLazySingleton<QRService>(() => QRService());
}
