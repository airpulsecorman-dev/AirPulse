import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);

  Future<User> call({
    required String username,
    required String email,
    required String password,
  }) =>
      _repo.register(username: username, email: email, password: password);
}

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);

  Future<User> call({required String email, required String password}) =>
      _repo.login(email: email, password: password);
}

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);

  Future<void> call() => _repo.logout();
}

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase(this._repo);

  Future<User?> call() => _repo.getCurrentUser();
}

class IsLoggedInUseCase {
  final AuthRepository _repo;
  IsLoggedInUseCase(this._repo);

  Future<bool> call() => _repo.isLoggedIn();
}
