import '../entities/server_session.dart';
import '../repositories/server_repository.dart';

class StartServerUseCase {
  final ServerRepository _repository;
  StartServerUseCase(this._repository);
  Future<ServerSession> call({int port = 8765}) =>
      _repository.startServer(port: port);
}

class StopServerUseCase {
  final ServerRepository _repository;
  StopServerUseCase(this._repository);
  Future<void> call() => _repository.stopServer();
}

class GetActiveSessionUseCase {
  final ServerRepository _repository;
  GetActiveSessionUseCase(this._repository);
  Future<ServerSession?> call() => _repository.getActiveSession();
}
