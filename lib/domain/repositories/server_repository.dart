import '../entities/server_session.dart';
import '../entities/song.dart';

abstract class ServerRepository {
  Future<ServerSession> startServer({int port = 8765});
  Future<void> stopServer();
  Future<ServerSession?> getActiveSession();
  Future<void> broadcastPlayerState(Map<String, dynamic> state);
  Stream<Map<String, dynamic>> get clientCommandStream;
  Stream<List<String>> get connectedClientsStream;
  Future<List<Song>> getStreamableSongs();
}
