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
  Future<User> updateProfile({
    required String userId,
    required String username,
    required String email,
  });
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}
