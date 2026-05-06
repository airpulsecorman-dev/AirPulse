import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref('AirPulse/users');
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  bool _calcIsMinor(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 18;
  }

  Future<UserModel> _fetchUserModel(String uid) async {
    final snap = await _db.child(uid).get();
    if (!snap.exists) {
      throw Exception('Usuario no encontrado en la base de datos.');
    }
    final data = Map<String, dynamic>.from(snap.value as Map);
    return UserModel.fromJson(data);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // getCurrentUser
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      return await _fetchUserModel(fbUser.uid);
    } catch (_) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // register
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<User> register({
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user!;
      await fbUser.updateDisplayName(username.trim());

      final isMinor = _calcIsMinor(birthDate);
      final now = DateTime.now();

      final model = UserModel(
        id: fbUser.uid,
        username: username.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        cedula: cedula.trim().isEmpty ? null : cedula.trim(),
        createdAt: now,
        birthDate: birthDate,
        subscriptionType: SubscriptionType.free,
        isMinor: isMinor,
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
        acceptedIntellectual: acceptedIntellectual,
      );

      await _db.child(fbUser.uid).set(model.toJson());
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // login
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _fetchUserModel(credential.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // signInWithGoogle
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Inicio de sesión cancelado.');

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final fbUser = userCredential.user!;

      // Si el usuario ya existe en la DB lo retornamos
      final snap = await _db.child(fbUser.uid).get();
      if (snap.exists) {
        return UserModel.fromJson(Map<String, dynamic>.from(snap.value as Map));
      }

      // Primera vez con Google: crear registro con datos mínimos
      final nameParts = (fbUser.displayName ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final now = DateTime.now();

      final model = UserModel(
        id: fbUser.uid,
        username: fbUser.email?.split('@').first ?? fbUser.uid,
        firstName: firstName,
        lastName: lastName,
        email: fbUser.email?.toLowerCase() ?? '',
        createdAt: now,
        birthDate: DateTime(2000), // se pedirá completar perfil
        subscriptionType: SubscriptionType.free,
        isMinor: false,
        acceptedTerms: false,
        acceptedPrivacy: false,
        acceptedIntellectual: false,
      );

      await _db.child(fbUser.uid).set(model.toJson());
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al iniciar sesión con Google.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // logout
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // isLoggedIn
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  // ────────────────────────────────────────────────────────────────────────────
  // updateProfile
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<User> updateProfile({
    required String userId,
    required String username,
    required String email,
  }) async {
    await _db.child(userId).update({
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
    });
    return await _fetchUserModel(userId);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // changePassword
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay sesión activa.');
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Error mapping
  // ────────────────────────────────────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo ya está registrado.';
      case 'invalid-email':
        return 'Correo inválido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación ($code).';
    }
  }
}
