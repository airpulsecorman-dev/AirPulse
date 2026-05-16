import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/server_session.dart';

/// Hook para controlar el servidor local y conexión de clientes.
ServerHookResult useServer(BuildContext context) {
  // Usar watch en lugar de read para que el hook se actualice cuando cambie el provider
  final provider = context.watch<ServerProvider>();

  // Asegurar que el widget se reconstruya cuando cambien propiedades relevantes
  useListenable(provider);

  return ServerHookResult(
    session: provider.session,
    isRunning: provider.isRunning,
    isStarting: provider.isStarting,
    error: provider.error,
    ngrokError: provider.ngrokError,
    connectedClients: provider.connectedClients,
    serverUrl: provider.serverUrl,
    qrPayload: provider.qrPayload,
    startServer: ({port = 8765, songs = const [], String? userId}) =>
        provider.startServer(port: port, songs: songs, userId: userId),
    stopServer: provider.stopServer,
    broadcastPlayerState: provider.broadcastPlayerState,
  );
}

class ServerHookResult {
  final ServerSession? session;
  final bool isRunning;
  final bool isStarting;
  final String? error;
  final String? ngrokError;
  final List<String> connectedClients;
  final String? serverUrl;
  final String? qrPayload;
  final Future<void> Function({int port, List<Song> songs, String? userId})
  startServer;
  final Future<void> Function() stopServer;
  final void Function(Map<String, dynamic>) broadcastPlayerState;

  const ServerHookResult({
    required this.session,
    required this.isRunning,
    required this.isStarting,
    required this.error,
    this.ngrokError,
    required this.connectedClients,
    required this.serverUrl,
    required this.qrPayload,
    required this.startServer,
    required this.stopServer,
    required this.broadcastPlayerState,
  });
}
