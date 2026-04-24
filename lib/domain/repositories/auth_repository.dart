import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> register({
    required String username,
    required String email,
    required String password,
  });
  Future<User> login({required String email, required String password});
  Future<void> logout();
  Future<bool> isLoggedIn();
}
