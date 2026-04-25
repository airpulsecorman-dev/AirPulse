class AppConstants {
  AppConstants._();

  static const String appName = 'AirPulse';
  static const String appVersion = '1.0.0';
  static const int defaultServerPort = 8765;
  static const String webAppUrl = 'https://18-anth.github.io/AirPulseWeb';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration seekDebounce = Duration(milliseconds: 200);
  static const int maxPlaylistNameLength = 50;
}
