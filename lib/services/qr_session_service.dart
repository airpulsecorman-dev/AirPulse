import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
  final String? serverUrl;

  const WebSessionData({
    required this.status,
    this.uid,
    this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarPath,
    this.serverUrl,
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
    final now = DateTime.now().millisecondsSinceEpoch;
    await _ref(sessionId).set({
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
      'expiresAt': now + _kTtlMs,
    });
  }

  // ──────────────────────────────────────────────────────────
  // WEB: escucha cambios en la sesión (Stream)
  // ──────────────────────────────────────────────────────────
  Stream<WebSessionData> watchSession(String sessionId) {
    return _ref(sessionId).onValue.map((event) {
      final data = event.snapshot.value;
      debugPrint('[QrSession] watchSession($sessionId) → $data');
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
        serverUrl: map['serverUrl'] as String?,
      );
    });
  }

  // ──────────────────────────────────────────────────────────
  // MÓVIL: aprueba la sesión escribiendo los datos del usuario
  // ──────────────────────────────────────────────────────────
  Future<void> approveWebSession(String sessionId, User user, {String? serverUrl}) async {
    await _ref(sessionId).update({
      'status': 'approved',
      'uid': user.id,
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'avatarPath': user.avatarPath,
      'approvedAt': ServerValue.timestamp,
      if (serverUrl != null) 'serverUrl': serverUrl,
    });
  }

  // ──────────────────────────────────────────────────────────
  // Elimina la sesión del RTDB (limpieza)
  // ──────────────────────────────────────────────────────────
  Future<void> deleteSession(String sessionId) async {
    await _ref(sessionId).remove();
  }

  // ──────────────────────────────────────────────────────────
  // MÓVIL: publica la sesión activa del servidor Shelf en RTDB
  // Permite que la web (mismo usuario) encuentre la URL del
  // servidor sin necesidad de escanear el QR de URL.
  // ──────────────────────────────────────────────────────────
  Future<void> publishServerSession({
    required String userId,
    required String serverUrl,
    required String sessionId,
  }) async {
    try {
      await _db.ref('server_sessions/$userId').set({
        'serverUrl': serverUrl,
        'sessionId': sessionId,
        'startedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[QrSession] publishServerSession failed (check RTDB rules): $e');
    }
  }

  Future<void> clearServerSession(String userId) async {
    try {
      await _db.ref('server_sessions/$userId').remove();
    } catch (e) {
      debugPrint('[QrSession] clearServerSession failed: $e');
    }
  }

  /// La web escucha este nodo para obtener la URL del servidor móvil
  /// del mismo usuario sin escanear QR.
  Stream<String?> watchServerSession(String userId) {
    return _db.ref('server_sessions/$userId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return Map<String, dynamic>.from(data)['serverUrl'] as String?;
    });
  }
}
