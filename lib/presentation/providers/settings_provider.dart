import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyNotifications = 'settings_notifications';
  static const _keyAudioQuality = 'settings_audio_quality';

  bool _darkModeEnabled = true;
  bool _notificationsEnabled = true;
  String _audioQuality = 'alta';

  bool get darkModeEnabled => _darkModeEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get audioQuality => _audioQuality;

  ThemeMode get themeMode =>
      _darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

  /// Carga las preferencias guardadas. Llamar una sola vez al inicio.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkModeEnabled = prefs.getBool(_keyDarkMode) ?? true;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _audioQuality = prefs.getString(_keyAudioQuality) ?? 'alta';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<void> setAudioQuality(String value) async {
    _audioQuality = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAudioQuality, value);
  }

  /// Limpia los directorios de caché de la aplicación.
  /// Devuelve los MB liberados (aprox).
  Future<double> clearCache() async {
    double freed = 0;

    Future<void> deleteDir(Directory dir) async {
      if (!await dir.exists()) return;
      final list = await dir.list(recursive: false).toList();
      for (final entity in list) {
        try {
          if (entity is File) {
            freed += await entity.length();
            await entity.delete();
          } else if (entity is Directory) {
            freed += await _dirSize(entity);
            await entity.delete(recursive: true);
          }
        } catch (_) {}
      }
    }

    try {
      final temp = await getTemporaryDirectory();
      await deleteDir(temp);
    } catch (_) {}

    try {
      final cache = await getApplicationCacheDirectory();
      await deleteDir(cache);
    } catch (_) {}

    return freed / (1024 * 1024); // en MB
  }

  Future<double> _dirSize(Directory dir) async {
    double size = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) size += await entity.length();
      }
    } catch (_) {}
    return size;
  }
}
