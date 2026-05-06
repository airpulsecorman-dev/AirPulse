import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'core/config/env_loader.dart';

// Las credenciales se leen en tiempo de ejecución desde assets/env.txt.
// Nunca hardcodear valores aquí.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvLoader.get('API_KEY'),
    authDomain: EnvLoader.get('AUTH_DOMAIN'),
    databaseURL: EnvLoader.get('DATABASE_URL'),
    projectId: EnvLoader.get('PROJECT_ID'),
    storageBucket: EnvLoader.get('STORAGE_BUCKET'),
    messagingSenderId: EnvLoader.get('MESSAGING_SENDER_ID'),
    appId: EnvLoader.get('APP_ID'),
    measurementId: EnvLoader.get('MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvLoader.get('API_KEY'),
    authDomain: EnvLoader.get('AUTH_DOMAIN'),
    databaseURL: EnvLoader.get('DATABASE_URL'),
    projectId: EnvLoader.get('PROJECT_ID'),
    storageBucket: EnvLoader.get('STORAGE_BUCKET'),
    messagingSenderId: EnvLoader.get('MESSAGING_SENDER_ID'),
    appId: EnvLoader.get('ANDROID_APP_ID'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: EnvLoader.get('API_KEY'),
    authDomain: EnvLoader.get('AUTH_DOMAIN'),
    databaseURL: EnvLoader.get('DATABASE_URL'),
    projectId: EnvLoader.get('PROJECT_ID'),
    storageBucket: EnvLoader.get('STORAGE_BUCKET'),
    messagingSenderId: EnvLoader.get('MESSAGING_SENDER_ID'),
    appId: EnvLoader.get('IOS_APP_ID'),
  );
}
