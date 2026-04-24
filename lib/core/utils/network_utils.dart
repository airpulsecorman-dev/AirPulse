import 'package:connectivity_plus/connectivity_plus.dart';

/// Verifica si hay conexión de red disponible.
Future<bool> hasNetworkConnection() async {
  final result = await Connectivity().checkConnectivity();
  return !result.contains(ConnectivityResult.none);
}

/// Verifica si hay conexión WiFi activa (requerida para el servidor local).
Future<bool> hasWifiConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result.contains(ConnectivityResult.wifi);
}

/// Construye una URL de stream para una canción en el servidor local.
String buildStreamUrl(String serverUrl, String songId) =>
    '$serverUrl/songs/$songId/stream';

/// Construye la URL del WebSocket del servidor local.
String buildWebSocketUrl(String serverUrl) =>
    serverUrl.replaceFirst('http://', 'ws://') + '/ws';
