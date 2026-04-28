import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _usersKey = 'airpulse_users';
  static const _sessionKey = 'airpulse_session';

  /// Devuelve un hash simple del password (no criptográfico, solo ofuscación local).
  String _hashPassword(String password) {
    // XOR + base64 para ofuscación básica sin paquete externo
    final bytes = utf8.encode(password);
    final salted = bytes.map((b) => b ^ 0x5A).toList();
    return base64Encode(salted);
  }

  Future<Map<String, dynamic>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    final emailLower = email.trim().toLowerCase();

    if (users.containsKey(emailLower)) {
      throw Exception('El correo ya está registrado.');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final userModel = UserModel(
      id: id,
      username: username.trim(),
      email: emailLower,
      createdAt: now,
    );

    users[emailLower] = {
      ...userModel.toJson(),
      'passwordHash': _hashPassword(password),
    };
    await _saveUsers(users);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, emailLower);

    return userModel;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    final emailLower = email.trim().toLowerCase();
    final entry = users[emailLower];

    if (entry == null) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final stored = Map<String, dynamic>.from(entry as Map);
    if (stored['passwordHash'] != _hashPassword(password)) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, emailLower);

    return UserModel.fromJson(stored);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;

    final users = await _loadUsers();
    final entry = users[email];
    if (entry == null) return null;

    return UserModel.fromJson(Map<String, dynamic>.from(entry as Map));
  }

  @override
  Future<User> updateProfile({
    required String userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = prefs.getString(_sessionKey);
    if (currentEmail == null) {
      throw Exception('Usuario no autenticado.');
    }

    final users = await _loadUsers();
    final emailLower = email.trim().toLowerCase();

    // Si el email cambió, verificar que no esté registrado
    if (currentEmail != emailLower && users.containsKey(emailLower)) {
      throw Exception('El correo ya está registrado.');
    }

    // Obtener datos actuales
    final currentEntry = users[currentEmail];
    if (currentEntry == null) {
      throw Exception('Usuario no encontrado.');
    }

    final stored = Map<String, dynamic>.from(currentEntry as Map);

    // Actualizar datos
    final updatedUser = UserModel(
      id: stored['id'] as String,
      username: username.trim(),
      email: emailLower,
      avatarPath: stored['avatarPath'] as String?,
      createdAt: DateTime.parse(stored['createdAt'] as String),
    );

    // Si el email cambió, eliminar entrada antigua
    if (currentEmail != emailLower) {
      users.remove(currentEmail);
    }

    // Guardar entrada actualizada
    users[emailLower] = {
      ...updatedUser.toJson(),
      'passwordHash': stored['passwordHash'],
    };

    await _saveUsers(users);

    // Actualizar sesión si el email cambió
    if (currentEmail != emailLower) {
      await prefs.setString(_sessionKey, emailLower);
    }

    return updatedUser;
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final users = await _loadUsers();
    final emailLower = email.trim().toLowerCase();
    final entry = users[emailLower];

    if (entry == null) {
      throw Exception('Usuario no encontrado.');
    }

    final stored = Map<String, dynamic>.from(entry as Map);

    // Verificar contraseña actual
    if (stored['passwordHash'] != _hashPassword(currentPassword)) {
      throw Exception('Contraseña actual incorrecta.');
    }

    // Actualizar con nueva contraseña
    stored['passwordHash'] = _hashPassword(newPassword);
    users[emailLower] = stored;

    await _saveUsers(users);
  }
}
