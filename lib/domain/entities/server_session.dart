import 'package:equatable/equatable.dart';

enum ServerStatus { stopped, starting, running, error }

class ServerSession extends Equatable {
  final String sessionId;
  final String localIp;
  final int port;
  final ServerStatus status;
  final String qrPayload;
  final List<String> connectedClients;
  final DateTime? startedAt;
  /// URL pública del servidor. Si se abrió un túnel ngrok, será la URL HTTPS.
  /// De lo contrario es la IP local (http://localIp:port).
  final String? publicUrl;

  const ServerSession({
    required this.sessionId,
    required this.localIp,
    required this.port,
    required this.status,
    required this.qrPayload,
    this.connectedClients = const [],
    this.startedAt,
    this.publicUrl,
  });

  String get localUrl => 'http://$localIp:$port';
  String get serverUrl => publicUrl ?? localUrl;

  ServerSession copyWith({
    ServerStatus? status,
    List<String>? connectedClients,
    String? publicUrl,
  }) {
    return ServerSession(
      sessionId: sessionId,
      localIp: localIp,
      port: port,
      status: status ?? this.status,
      qrPayload: qrPayload,
      connectedClients: connectedClients ?? this.connectedClients,
      startedAt: startedAt,
      publicUrl: publicUrl ?? this.publicUrl,
    );
  }

  @override
  List<Object?> get props => [sessionId, localIp, port, status, publicUrl];
}
