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

  const ServerSession({
    required this.sessionId,
    required this.localIp,
    required this.port,
    required this.status,
    required this.qrPayload,
    this.connectedClients = const [],
    this.startedAt,
  });

  String get serverUrl => 'http://$localIp:$port';

  ServerSession copyWith({
    ServerStatus? status,
    List<String>? connectedClients,
  }) {
    return ServerSession(
      sessionId: sessionId,
      localIp: localIp,
      port: port,
      status: status ?? this.status,
      qrPayload: qrPayload,
      connectedClients: connectedClients ?? this.connectedClients,
      startedAt: startedAt,
    );
  }

  @override
  List<Object?> get props => [sessionId, localIp, port, status];
}
