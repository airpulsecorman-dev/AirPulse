import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      androidStopForegroundOnPause: false,
      notificationColor: Color(0xFF1A1A2E),
    ),
  );

  setupDependencies(audioHandler);
  runApp(const AirPulseApp());
}
