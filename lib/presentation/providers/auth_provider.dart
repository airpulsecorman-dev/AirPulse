import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

const _kQrSessionKey = 'qr_session_user';
const _kQrSessionIdKey = 'qr_session_id';
const _kCachedUserKey = 'cached_auth_user';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  String? _qrSessionId;

  AuthProvider(this._repo) {
    _init();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get qrSessionId => _qrSessionId;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Restaurar una sesión QR persistida (web y escritorio).
    if (kIsWeb) {
      final json = prefs.getString(_kQrSessionKey);
      if (json != null) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _currentUser = User(
            id: map['id'] as String,
            username: map['username'] as String,
            firstName: map['firstName'] as String? ?? '',
            lastName: map['lastName'] as String? ?? '',
            email: map['email'] as String,
            avatarPath: map['avatarPath'] as String?,
            createdAt: DateTime.now(),
            birthDate: DateTime(2000),
            isMinor: false,
          );
          _qrSessionId = prefs.getString(_kQrSessionIdKey);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        } catch (_) {
          await prefs.remove(_kQrSessionKey);
          await prefs.remove(_kQrSessionIdKey);
        }
      }
    }

    // Caché independiente de Firebase: permite abrir la app después de
    // cerrar el proceso desde Android recientes o después de reiniciar.
    final cachedJson = prefs.getString(_kCachedUserKey);
    if (cachedJson != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(cachedJson) as Map);
        _currentUser = User(
          id: map['id'] as String,
          username: map['username'] as String,
          firstName: map['firstName'] as String? ?? '',
          lastName: map['lastName'] as String? ?? '',
          email: map['email'] as String,
          cedula: map['cedula'] as String?,
          avatarPath: map['avatarPath'] as String?,
          createdAt: DateTime.parse(
            map['createdAt'] as String? ??
                DateTime.now().toIso8601String(),
          ),
          birthDate: DateTime.parse(
            map['birthDate'] as String? ??
                DateTime(2000).toIso8601String(),
          ),
          subscriptionType: SubscriptionType.values.firstWhere(
            (type) => type.name == (map['subscriptionType'] as String? ?? 'free'),
            orElse: () => SubscriptionType.free,
          ),
          isMinor: map['isMinor'] as bool? ?? false,
          acceptedTerms: map['acceptedTerms'] as bool? ?? false,
          acceptedPrivacy: map['acceptedPrivacy'] as bool? ?? false,
          acceptedIntellectual:
              map['acceptedIntellectual'] as bool? ?? false,
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
      } catch (_) {
        await prefs.remove(_kCachedUserKey);
      }
    }

    final user = await GetCurrentUserUseCase(_repo).call();
    _currentUser = user;
    if (user != null) {
      await _cacheUser(user);
    } else {
      await prefs.remove(_kCachedUserKey);
    }
    _status = user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUserKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'cedula': user.cedula,
      'avatarPath': user.avatarPath,
      'createdAt': user.createdAt.toIso8601String(),
      'birthDate': user.birthDate.toIso8601String(),
      'subscriptionType': user.subscriptionType.name,
      'isMinor': user.isMinor,
      'acceptedTerms': user.acceptedTerms,
      'acceptedPrivacy': user.acceptedPrivacy,
      'acceptedIntellectual': user.acceptedIntellectual,
    }));
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await LoginUseCase(
        _repo,
      ).call(email: email, password: password);
      await _cacheUser(_currentUser!);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await RegisterUseCase(_repo).call(
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
      await _cacheUser(_currentUser!);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await GoogleSignInUseCase(_repo).call();
      await _cacheUser(_currentUser!);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesión a partir de los datos aprobados vía QR (RTDB).
  /// Usado en el flujo estilo WhatsApp Web: el móvil aprueba → la web obtiene
  /// los datos del usuario desde Realtime Database y los carga en el provider.
  void loginFromQRSession({
    required String uid,
    required String email,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarPath,
    String? sessionId,
  }) {
    _qrSessionId = sessionId;
    _currentUser = User(
      id: uid,
      username: username ?? email.split('@').first,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
      birthDate: DateTime(2000),
      isMinor: false,
    );
    _status = AuthStatus.authenticated;
    // Persistir la sesión también en Android/iOS al matar el proceso.
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString(_kQrSessionKey, jsonEncode({
        'id': uid,
        'email': email,
        'username': _currentUser!.username,
        'firstName': firstName,
        'lastName': lastName,
        'avatarPath': avatarPath,
      }));
      await _cacheUser(_currentUser!);
      if (sessionId != null) {
        await prefs.setString(_kQrSessionIdKey, sessionId);
      }
    });
    notifyListeners();
  }

  Future<void> logout() async {
    await LogoutUseCase(_repo).call();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserKey);
    await prefs.remove(_kQrSessionKey);
    await prefs.remove(_kQrSessionIdKey);
    _qrSessionId = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> completeGoogleOnboarding({
    required DateTime birthDate,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
    required bool acceptedIntellectual,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _repo.completeGoogleOnboarding(
        userId: _currentUser!.id,
        birthDate: birthDate,
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
        acceptedIntellectual: acceptedIntellectual,
      );
      await _cacheUser(_currentUser!);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Usuario no autenticado';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repo.updateProfile(
        userId: _currentUser!.id,
        username: username,
        email: email,
      );
      await _cacheUser(_currentUser!);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Usuario no autenticado';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.changePassword(
        email: _currentUser!.email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
