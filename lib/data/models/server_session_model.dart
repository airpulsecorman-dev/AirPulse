import '../../domain/entities/server_session.dart';

class ServerSessionModel extends ServerSession {
  const ServerSessionModel({
    required super.sessionId,
    required super.localIp,
    required super.port,
    required super.status,
    required super.qrPayload,
    super.connectedClients,
    super.startedAt,
  });

  factory ServerSessionModel.fromJson(Map<String, dynamic> json) {
    return ServerSessionModel(
      sessionId: json['sessionId'] as String,
      localIp: json['localIp'] as String,
      port: json['port'] as int,
      status: ServerStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ServerStatus.stopped,
      ),
      qrPayload: json['qrPayload'] as String,
      connectedClients:
          (json['connectedClients'] as List<dynamic>?)?.cast<String>() ?? [],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'localIp': localIp,
      'port': port,
      'status': status.name,
      'qrPayload': qrPayload,
      'connectedClients': connectedClients,
      'startedAt': startedAt?.toIso8601String(),
    };
  }
}
