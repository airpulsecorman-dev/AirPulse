import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/config/env_loader.dart';
import 'core/di/service_locator.dart';
import 'firebase_options.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar el handler de audio: activa la notificación en pantalla de
  // bloqueo, controles de Bluetooth/auriculares y reproducción en background.
  final audioHandler = await AudioService.init<AirPulseAudioHandler>(
    builder: () => AirPulseAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.airpulse.channel.audio',
      androidNotificationChannelName: 'AirPulse',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF1A1A2E),
    ),
  );

  await setupDependencies(audioHandler);
  runApp(const AirPulseApp());
}
