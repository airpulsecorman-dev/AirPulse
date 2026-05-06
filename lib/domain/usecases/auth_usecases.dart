import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);

  Future<User> call({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String cedula,
    required DateTime birthDate,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
    required bool acceptedIntellectual,
  }) =>
      _repo.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        cedula: cedula,
        birthDate: birthDate,
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
        acceptedIntellectual: acceptedIntellectual,
      );
}

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);

  Future<User> call({required String email, required String password}) =>
      _repo.login(email: email, password: password);
}

class GoogleSignInUseCase {
  final AuthRepository _repo;
  GoogleSignInUseCase(this._repo);

  Future<User> call() => _repo.signInWithGoogle();
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
