import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Abre un túnel HTTPS via ngrok apuntando al servidor Shelf local.
/// Solo disponible en Android (usa ngrok-java via MethodChannel).
/// En iOS y otras plataformas devuelve null (sin túnel).
class NgrokService {
  static const _channel = MethodChannel('com.airpulse/ngrok');
  static const _authtoken = '3DNRmnh96kv1pNGMOQ0vOLNlyQL_3Br7DyYiLyGJQe8BNJij2';

  String? _tunnelUrl;
  String? _lastError;
  String? get tunnelUrl => _tunnelUrl;
  String? get lastError => _lastError;
  bool get isActive => _tunnelUrl != null;

  /// Inicia el túnel ngrok hacia [port]. Devuelve la URL HTTPS pública
  /// o null si la plataforma no soporta ngrok.
  Future<String?> startTunnel(int port) async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    _lastError = null;
    try {
      final url = await _channel.invokeMethod<String>('startTunnel', {
        'port': port,
        'authtoken': _authtoken,
      });
      _tunnelUrl = url;
      // ignore: avoid_print
      print('[NgrokService] tunnel started: $url');
      return url;
    } on PlatformException catch (e) {
      _lastError = e.message;
      // ignore: avoid_print
      print('[NgrokService] startTunnel error code=${e.code} msg=${e.message} details=${e.details}');
      _tunnelUrl = null;
      return null;
    }
  }

  /// Detiene el túnel ngrok activo.
  Future<void> stopTunnel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('stopTunnel');
    } catch (_) {}
    _tunnelUrl = null;
  }
}
