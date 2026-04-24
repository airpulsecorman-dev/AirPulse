import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/widgets.dart';

class QRService {
  /// Genera el widget QR a partir del payload JSON de la sesión del servidor.
  Widget buildQRWidget({
    required String payload,
    double size = 200,
    Color foregroundColor = const Color(0xFF000000),
    Color backgroundColor = const Color(0xFFFFFFFF),
  }) {
    return QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  /// Construye el payload que el navegador/PWA usará para conectarse.
  String buildPayload({
    required String serverUrl,
    required String sessionId,
  }) {
    return jsonEncode({
      'type': 'airpulse_connect',
      'url': serverUrl,
      'sessionId': sessionId,
      'version': '1',
    });
  }

  /// Parsea un QR escaneado y devuelve los datos de conexión.
  Map<String, dynamic>? parseScannedQR(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] == 'airpulse_connect') return data;
      return null;
    } catch (_) {
      return null;
    }
  }
}
