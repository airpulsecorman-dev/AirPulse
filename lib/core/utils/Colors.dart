import 'package:flutter/material.dart';

/// Clase centralizada para todos los colores de la aplicación AirPulse
class AppColors {
  // ============================================
  // COLORES PRIMARIOS Y BRAND
  // ============================================

  /// Color primario de la aplicación (Rosa vibrante)
  static const Color primary = Color(0xFFFF4D8B);

  /// Color semilla del tema (Púrpura)
  static const Color themeSeed = Color(0xFF6750A4);

  // ============================================
  // BACKGROUNDS Y SUPERFICIES
  // ============================================

  /// Background principal (Azul oscuro profundo)
  static const Color backgroundDark = Color(0xFF0D1B2A);

  /// Background secundario para notificaciones
  static const Color backgroundNotification = Color(0xFF1A1A2E);

  /// Background de cards y superficies (Azul grisáceo)
  static const Color surface = Color(0xFF1A2D42);

  /// Background alternativo de superficie
  static const Color surfaceAlt = Color(0xFF1E2A38);

  /// Background para pricing cards
  static const Color surfacePricing = Color(0xFF0F3460);
  static const Color backgroundPricing = Color(0xFF16213E);

  // ============================================
  // COLORES DE TEXTO
  // ============================================

  /// Texto principal (Blanco)
  static const Color textPrimary = Colors.white;

  /// Texto secundario (Blanco con opacidad)
  static const Color textSecondary = Colors.white70;

  /// Texto terciario/hint (Gris azulado claro)
  static const Color textTertiary = Color(0xFF8899AA);

  /// Texto muted/deshabilitado (Gris azulado oscuro)
  static const Color textMuted = Color(0xFF566D80);

  // ============================================
  // BORDES Y DIVISORES
  // ============================================

  /// Color de bordes y dividers
  static const Color border = Color(0xFF334455);

  /// Color de bordes sutiles
  static const Color borderSubtle = Color(0xFF8899AA);

  // ============================================
  // COLORES DE ESTADO (SUCCESS, ERROR, WARNING, INFO)
  // ============================================

  /// Color de éxito (Verde)
  static const Color success = Color(0xFF4CAF50);
  static const Color successAlt = Colors.green;
  static const Color successAccent = Colors.greenAccent;

  /// Color de error/peligro (Rojo)
  static const Color error = Colors.red;
  static const Color errorAccent = Colors.redAccent;

  /// Color de advertencia (Naranja/Ámbar)
  static const Color warning = Colors.orange;
  static const Color warningAmber = Colors.amber;

  /// Color de información (Azul)
  static const Color info = Color(0xFF2196F3);

  // ============================================
  // COLORES INTERACTIVOS
  // ============================================

  /// Color de favoritos/like
  static const Color favorite = Color(0xFFFF4D8B);

  /// Color de iconos activos
  static const Color iconActive = Color(0xFFFF4D8B);

  /// Color de iconos inactivos
  static const Color iconInactive = Color(0xFF8899AA);

  /// Color de slider activo
  static const Color sliderActive = Color(0xFFFF4D8B);

  /// Color de slider inactivo
  static const Color sliderInactive = Color(0xFF334455);

  // ============================================
  // COLORES DE SHARE/SOCIAL
  // ============================================

  /// Color de WhatsApp
  static const Color whatsapp = Color(0xFF4CAF50);

  /// Color de compartir/share
  static const Color share = Color(0xFFFF4D8B);

  /// Color de Nearby
  static const Color nearby = Color(0xFF2196F3);

  // ============================================
  // COLORES BÁSICOS Y UTILIDADES
  // ============================================

  /// Blanco puro
  static const Color white = Colors.white;

  /// Negro puro
  static const Color black = Colors.black;

  /// Transparente
  static const Color transparent = Colors.transparent;

  /// Gris estándar
  static const Color grey = Colors.grey;

  /// QR Foreground (Negro)
  static const Color qrForeground = Color(0xFF000000);

  /// QR Background (Blanco)
  static const Color qrBackground = Color(0xFFFFFFFF);

  // ============================================
  // MÉTODOS DE UTILIDAD
  // ============================================

  /// Obtener color primario con opacidad personalizada
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }

  /// Obtener color de superficie con opacidad personalizada
  static Color surfaceWithOpacity(double opacity) {
    return surface.withOpacity(opacity);
  }

  /// Obtener color blanco con opacidad personalizada
  static Color whiteWithOpacity(double opacity) {
    return white.withOpacity(opacity);
  }

  /// Obtener color negro con opacidad personalizada
  static Color blackWithOpacity(double opacity) {
    return black.withOpacity(opacity);
  }
}
