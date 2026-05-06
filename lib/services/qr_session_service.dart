import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/user.dart';

/// Estatus posibles de una sesión web QR.
enum WebSessionStatus { pending, approved, expired, unknown }

/// Datos de la sesión web una vez aprobada por el móvil.
class WebSessionData {
  final WebSessionStatus status;
  final String? uid;
  final String? email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarPath;

  const WebSessionData({
    required this.status,
    this.uid,
    this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarPath,
  });
}

/// Servicio que gestiona las sesiones web QR estilo WhatsApp Web.
///
/// Flujo:
///   1. Web genera un [sessionId] y llama a [createWebSession].
///   2. Web muestra el [sessionId] como QR y escucha [watchSession].
///   3. Móvil escanea el QR, llama a [approveWebSession] con los datos del usuario.
///   4. Web detecta el cambio en RTDB y navega a la pantalla principal.
///   5. Se llama a [deleteSession] para limpiar el nodo.
class QrSessionService {
  static const _kRoot = 'web_sessions';
  // Las sesiones expiran tras 5 minutos.
  static const _kTtlMs = 5 * 60 * 1000;

  final FirebaseDatabase _db;

  QrSessionService({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference _ref(String sessionId) =>
      _db.ref('$_kRoot/$sessionId');

  // ──────────────────────────────────────────────────────────
  // WEB: crea la sesión en estado "pending"
  // ──────────────────────────────────────────────────────────
  Future<void> createWebSession(String sessionId) async {
    await _ref(sessionId).set({
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
      'expiresAt': ServerValue.timestamp, // actualizado abajo
    });
    // Actualizar expiresAt con la marca real + TTL
    final now = DateTime.now().millisecondsSinceEpoch;
    await _ref(sessionId).update({'expiresAt': now + _kTtlMs});
  }

  // ──────────────────────────────────────────────────────────
  // WEB: escucha cambios en la sesión (Stream)
  // ──────────────────────────────────────────────────────────
  Stream<WebSessionData> watchSession(String sessionId) {
    return _ref(sessionId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return const WebSessionData(status: WebSessionStatus.unknown);
      }
      final map = Map<String, dynamic>.from(data);
      final statusStr = map['status'] as String? ?? '';
      final status = switch (statusStr) {
        'approved' => WebSessionStatus.approved,
        'expired' => WebSessionStatus.expired,
        _ => WebSessionStatus.pending,
      };
      return WebSessionData(
        status: status,
        uid: map['uid'] as String?,
        email: map['email'] as String?,
        username: map['username'] as String?,
        firstName: map['firstName'] as String?,
        lastName: map['lastName'] as String?,
        avatarPath: map['avatarPath'] as String?,
      );
    });
  }

  // ──────────────────────────────────────────────────────────
  // MÓVIL: aprueba la sesión escribiendo los datos del usuario
  // ──────────────────────────────────────────────────────────
  Future<void> approveWebSession(String sessionId, User user) async {
    await _ref(sessionId).update({
      'status': 'approved',
      'uid': user.id,
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'avatarPath': user.avatarPath,
      'approvedAt': ServerValue.timestamp,
    });
  }

  // ──────────────────────────────────────────────────────────
  // Elimina la sesión del RTDB (limpieza)
  // ──────────────────────────────────────────────────────────
  Future<void> deleteSession(String sessionId) async {
    await _ref(sessionId).remove();
  }
}
