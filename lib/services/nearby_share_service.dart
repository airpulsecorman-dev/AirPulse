import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/song.dart';

enum NearbyRole { idle, advertising, discovering }

class NearbyDevice {
  final String endpointId;
  final String name;
  bool connected;

  NearbyDevice({
    required this.endpointId,
    required this.name,
    this.connected = false,
  });
}

class NearbyTransferProgress {
  final String songTitle;
  final double progress; // 0.0 – 1.0
  final bool done;
  final bool error;

  const NearbyTransferProgress({
    required this.songTitle,
    required this.progress,
    this.done = false,
    this.error = false,
  });
}

/// Servicio que encapsula la API de Google Nearby Connections
/// para compartir canciones por Bluetooth / WiFi Direct.
class NearbyShareService {
  final Nearby _nearby = Nearby();

  NearbyRole _role = NearbyRole.idle;
  NearbyRole get role => _role;

  // Dispositivos descubiertos (cuando estamos en modo discover)
  final _devicesController = StreamController<List<NearbyDevice>>.broadcast();
  Stream<List<NearbyDevice>> get devicesStream => _devicesController.stream;
  final List<NearbyDevice> _devices = [];

  // Progreso de transferencia (emisor y receptor)
  final _progressController =
      StreamController<NearbyTransferProgress>.broadcast();
  Stream<NearbyTransferProgress> get progressStream =>
      _progressController.stream;

  // Payloads en curso: payloadId → songTitle
  final Map<int, String> _pendingPayloadTitles = {};

  // Callbacks de la UI
  void Function(String endpointId, String name)? onConnectionRequest;
  void Function(String songTitle, String filePath)? onSongReceived;

  String _userName = 'AirPulse';

  /// Solicitar permisos necesarios (llamar antes de start).
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      // Permisos base requeridos siempre
      final basePerms = [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
      final baseStatuses = await basePerms.request();
      debugPrint('[Nearby] base permissions: $baseStatuses');

      final baseGranted = baseStatuses.values.every(
        (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
      );
      if (!baseGranted) {
        debugPrint('[Nearby] base permissions denied');
        return false;
      }

      // nearbyWifiDevices solo existe en Android 13+ (API 33)
      // En versiones anteriores, el permiso no existe y debemos ignorar su estado
      if (Platform.isAndroid) {
        try {
          final wifiStatus = await Permission.nearbyWifiDevices.request();
          debugPrint('[Nearby] nearbyWifiDevices: $wifiStatus');
          // Si el permiso no existe en el sistema, devuelve permanentlyDenied o denied.
          // Solo bloqueamos si explícitamente el usuario lo denegó y el sistema lo reconoce.
          // Intentamos continuar de todos modos — BLE puede funcionar sin él.
        } catch (e) {
          debugPrint('[Nearby] nearbyWifiDevices not available: $e');
        }
      }

      // El GPS debe estar activo (requerimiento de Nearby Connections)
      final locationEnabled = await Permission.location.serviceStatus.isEnabled;
      debugPrint('[Nearby] GPS enabled: $locationEnabled');
      return locationEnabled;
    } catch (e) {
      debugPrint('[Nearby] requestPermissions error: $e');
      return false;
    }
  }

  /// Inicia el modo Anuncio (el dispositivo es el que comparte canciones).
  Future<bool> startAdvertising(String userName) async {
    _userName = userName;
    try {
      await _nearby.stopAdvertising();
    } catch (_) {}
    try {
      await _nearby.startAdvertising(
        userName,
        Strategy.P2P_STAR,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: 'com.airpulse.nearby',
      );
      _role = NearbyRole.advertising;
      return true;
    } catch (e) {
      debugPrint('[Nearby] startAdvertising error: $e');
      return false;
    }
  }

  /// Inicia el modo Descubrimiento (el dispositivo busca hosts cercanos).
  Future<bool> startDiscovery(String userName) async {
    _userName = userName;
    _devices.clear();
    _devicesController.add([]);
    try {
      await _nearby.stopDiscovery();
    } catch (_) {}
    try {
      await _nearby.startDiscovery(
        userName,
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, serviceId) {
          debugPrint(
            '[Nearby] onEndpointFound id=$id name=$name serviceId=$serviceId',
          );
          if (!_devices.any((d) => d.endpointId == id)) {
            _devices.add(NearbyDevice(endpointId: id, name: name));
            _devicesController.add(List.unmodifiable(_devices));
          }
        },
        onEndpointLost: (id) {
          debugPrint('[Nearby] onEndpointLost id=$id');
          _devices.removeWhere((d) => d.endpointId == id);
          _devicesController.add(List.unmodifiable(_devices));
        },
        serviceId: 'com.airpulse.nearby',
      );
      _role = NearbyRole.discovering;
      return true;
    } catch (e) {
      debugPrint('[Nearby] startDiscovery error: $e');
      return false;
    }
  }

  /// Solicitar conexión con un dispositivo descubierto.
  Future<bool> connectToDevice(String endpointId) async {
    try {
      await _nearby.requestConnection(
        _userName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      return true;
    } catch (e) {
      debugPrint('[Nearby] requestConnection error: $e');
      return false;
    }
  }

  /// Aceptar automáticamente la conexión entrante.
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('[Nearby] Connection initiated with ${info.endpointName}');
    onConnectionRequest?.call(endpointId, info.endpointName);
    // En modo advertising el dispositivo aún no está en la lista; agregarlo
    if (!_devices.any((d) => d.endpointId == endpointId)) {
      _devices.add(
        NearbyDevice(endpointId: endpointId, name: info.endpointName),
      );
      _devicesController.add(List.unmodifiable(_devices));
    }
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    final connected = status == Status.CONNECTED;
    debugPrint('[Nearby] Connection result $endpointId: $status');
    final idx = _devices.indexWhere((d) => d.endpointId == endpointId);
    if (idx >= 0) {
      _devices[idx] = NearbyDevice(
        endpointId: endpointId,
        name: _devices[idx].name,
        connected: connected,
      );
    } else if (connected) {
      // En modo advertising los dispositivos no están en _devices aún
      _devices.add(
        NearbyDevice(endpointId: endpointId, name: endpointId, connected: true),
      );
    }
    _devicesController.add(List.unmodifiable(_devices));
  }

  void _onDisconnected(String endpointId) {
    debugPrint('[Nearby] Disconnected from $endpointId');
    final idx = _devices.indexWhere((d) => d.endpointId == endpointId);
    if (idx >= 0) {
      _devices[idx] = NearbyDevice(
        endpointId: endpointId,
        name: _devices[idx].name,
        connected: false,
      );
      _devicesController.add(List.unmodifiable(_devices));
    }
  }

  // ── Envío de archivo ─────────────────────────────────────────────────────

  /// Envía una canción a un dispositivo conectado.
  Future<void> sendSong(String endpointId, Song song) async {
    try {
      // Primero enviar metadatos como bytes
      final meta = jsonEncode({
        'type': 'song_meta',
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'fileName': song.filePath.split('/').last,
      });
      await _nearby.sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(meta)),
      );

      // Luego enviar el archivo
      final payloadId = await _nearby.sendFilePayload(
        endpointId,
        song.filePath,
      );
      _pendingPayloadTitles[payloadId] = song.title;
    } catch (e) {
      debugPrint('[Nearby] sendSong error: $e');
      _progressController.add(
        NearbyTransferProgress(songTitle: song.title, progress: 0, error: true),
      );
    }
  }

  // ── Recepción de payload ──────────────────────────────────────────────────

  String? _incomingTitle;
  String? _incomingFileName;
  // Mapa payloadId → ruta temporal del archivo (uri)
  final Map<int, String> _pendingFilePaths = {};

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type == PayloadType.BYTES) {
      try {
        final decoded = utf8.decode(payload.bytes!);
        final map = jsonDecode(decoded) as Map<String, dynamic>;
        if (map['type'] == 'song_meta') {
          _incomingTitle = map['title'] as String?;
          _incomingFileName = map['fileName'] as String?;
        }
      } catch (_) {}
    } else if (payload.type == PayloadType.FILE) {
      final path = payload.uri ?? payload.filePath;
      if (path != null) {
        _pendingFilePaths[payload.id] = path;
      }
      final title = _incomingTitle ?? 'Canción recibida';
      _pendingPayloadTitles[payload.id] = title;
    }
  }

  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) async {
    final title = _pendingPayloadTitles[update.id] ?? 'Archivo';
    final progress =
        update.bytesTransferred /
        (update.totalBytes == 0 ? 1 : update.totalBytes);

    if (update.status == PayloadStatus.SUCCESS) {
      _pendingPayloadTitles.remove(update.id);
      final tempPath = _pendingFilePaths.remove(update.id);
      if (tempPath != null) {
        await _moveReceivedFile(tempPath, title);
      }
      _progressController.add(
        NearbyTransferProgress(songTitle: title, progress: 1.0, done: true),
      );
    } else if (update.status == PayloadStatus.FAILURE) {
      _pendingPayloadTitles.remove(update.id);
      _pendingFilePaths.remove(update.id);
      _progressController.add(
        NearbyTransferProgress(
          songTitle: title,
          progress: progress,
          error: true,
        ),
      );
    } else {
      _progressController.add(
        NearbyTransferProgress(
          songTitle: title,
          progress: progress.clamp(0.0, 1.0),
        ),
      );
    }
  }

  /// Mueve el archivo recibido a la carpeta de música de la app.
  Future<String?> _moveReceivedFile(String tempPath, String title) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/received_songs');
      await musicDir.create(recursive: true);

      final fileName =
          _incomingFileName ?? '${title.replaceAll(RegExp(r'[^\w]'), '_')}.mp3';
      final dest = '${musicDir.path}/$fileName';

      final src = File(tempPath);
      await src.copy(dest);
      try {
        await src.delete();
      } catch (_) {}

      onSongReceived?.call(title, dest);
      return dest;
    } catch (e) {
      debugPrint('[Nearby] _moveReceivedFile error: $e');
      return null;
    }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  Future<void> stop() async {
    try {
      await _nearby.stopAllEndpoints();
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
    } catch (_) {}
    _role = NearbyRole.idle;
    _devices.clear();
    if (!_devicesController.isClosed) {
      _devicesController.add([]);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _devicesController.close();
    await _progressController.close();
  }
}
