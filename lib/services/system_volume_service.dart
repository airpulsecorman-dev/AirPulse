import 'dart:async';
import 'package:flutter/services.dart';

/// Servicio para sincronizar el volumen del sistema Android con la app.
class SystemVolumeService {
  static const platform = MethodChannel('com.airpulse/volume');

  static final SystemVolumeService _instance = SystemVolumeService._internal();

  final _volumeController = StreamController<double>.broadcast();
  bool _isListening = false;

  factory SystemVolumeService() {
    return _instance;
  }

  SystemVolumeService._internal();

  Stream<double> get volumeStream => _volumeController.stream;

  /// Inicia la escucha de cambios de volumen del sistema
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;

    try {
      // Configurar el handler para llamadas de método desde Android
      platform.setMethodCallHandler(_handleMethodCall);

      // Iniciar el listener en Android
      await platform.invokeMethod('startVolumeListener');
    } catch (e) {
      print('Error iniciando volume listener: $e');
      _isListening = false;
    }
  }

  /// Detiene la escucha de cambios de volumen del sistema
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;

    try {
      await platform.invokeMethod('stopVolumeListener');
    } catch (e) {
      print('Error deteniendo volume listener: $e');
    }
  }

  /// Establece el volumen del sistema
  Future<void> setVolume(double volume) async {
    try {
      await platform.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Maneja las llamadas de método desde Android
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVolumeChanged':
        final volume = call.arguments['volume'] as double?;
        if (volume != null) {
          _volumeController.add(volume);
        }
        break;
    }
  }

  void dispose() {
    stopListening();
    _volumeController.close();
  }
}
