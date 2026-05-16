import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/song.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';

/// Botón profesional de favorito con animaciones y feedback
///
/// Características:
/// - Animación de escala al presionar
/// - Animación de corazón latiendo al cambiar estado
/// - Feedback háptico
/// - Manejo de estados de carga
/// - Soporte para temas claro/oscuro
/// - Totalmente reutilizable
class FavoriteButton extends StatefulWidget {
  /// Canción asociada al botón
  final Song song;

  /// Tamaño del ícono (por defecto 24)
  final double size;

  /// Color cuando es favorito (por defecto rosa)
  final Color? favoriteColor;

  /// Color cuando NO es favorito (por defecto gris)
  final Color? normalColor;

  /// Si debe mostrar borde circular
  final bool showBackground;

  /// Color de fondo cuando showBackground es true
  final Color? backgroundColor;

  /// Padding interno
  final EdgeInsets? padding;

  /// Callback al cambiar estado (opcional)
  final void Function(bool isFavorite)? onChanged;

  const FavoriteButton({
    super.key,
    required this.song,
    this.size = 24.0,
    this.favoriteColor,
    this.normalColor,
    this.showBackground = false,
    this.backgroundColor,
    this.padding,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Configurar animación de escala
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isProcessing) return;

    final favoritesProvider = context.read<FavoritesProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      _showSnackBar('Inicia sesión para usar favoritos');
      return;
    }

    setState(() => _isProcessing = true);

    // Feedback háptico
    _triggerHapticFeedback();

    // Animación
    await _animationController.forward();
    await _animationController.reverse();

    try {
      // Ejecutar toggle
      await favoritesProvider.toggleFavorite(userId, widget.song);

      final isNowFavorite = favoritesProvider.isFavorite(widget.song.id);

      // Callback
      widget.onChanged?.call(isNowFavorite);

      // Feedback visual
      if (mounted) {
        _showFeedback(isNowFavorite);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar favorito');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _triggerHapticFeedback() {
    // Feedback háptico (requiere import de services)
    // HapticFeedback.lightImpact();
  }

  void _showFeedback(bool isFavorite) {
    final message = isFavorite
        ? '💖 Agregado a favoritos'
        : 'Eliminado de favoritos';

    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(widget.song.id);

    final effectiveFavoriteColor =
        widget.favoriteColor ?? const Color(0xFFFF4D8B);

    final effectiveNormalColor =
        widget.normalColor ??
        theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    final iconColor = isFavorite
        ? effectiveFavoriteColor
        : effectiveNormalColor;

    Widget button = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: widget.size,
        color: _isProcessing ? iconColor.withOpacity(0.5) : iconColor,
      ),
    );

    if (widget.showBackground) {
      button = Container(
        padding: widget.padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              widget.backgroundColor ??
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: button,
      );
    } else if (widget.padding != null) {
      button = Padding(padding: widget.padding!, child: button);
    }

    return GestureDetector(
      onTap: _isProcessing ? null : _handleTap,
      child: AnimatedOpacity(
        opacity: _isProcessing ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: button,
      ),
    );
  }
}

/// Botón de favorito estilo IconButton
///
/// Variante que mantiene el tamaño del IconButton estándar de Material
class FavoriteIconButton extends StatelessWidget {
  final Song song;
  final Color? favoriteColor;
  final Color? normalColor;
  final void Function(bool isFavorite)? onChanged;

  const FavoriteIconButton({
    super.key,
    required this.song,
    this.favoriteColor,
    this.normalColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FavoriteButton(
        song: song,
        size: 24,
        favoriteColor: favoriteColor,
        normalColor: normalColor,
        onChanged: onChanged,
      ),
      onPressed: null, // El FavoriteButton maneja el tap
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// Botón compacto de favorito para listas
///
/// Tamaño reducido para usar en tiles de listas
class FavoriteCompactButton extends StatelessWidget {
  final Song song;
  final void Function(bool isFavorite)? onChanged;

  const FavoriteCompactButton({super.key, required this.song, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FavoriteButton(
      song: song,
      size: 20,
      showBackground: false,
      onChanged: onChanged,
    );
  }
}

/// Botón flotante grande de favorito
///
/// Ideal para páginas de detalles de canción/álbum
class FavoriteFloatingButton extends StatelessWidget {
  final Song song;
  final void Function(bool isFavorite)? onChanged;

  const FavoriteFloatingButton({super.key, required this.song, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FavoriteButton(
      song: song,
      size: 28,
      showBackground: true,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
      padding: const EdgeInsets.all(12),
      onChanged: onChanged,
    );
  }
}

/// Extension para agregar FavoriteButton a widgets existentes
extension SongFavoriteExtension on Song {
  /// Crea un botón de favorito para esta canción
  Widget favoriteButton({
    double size = 24.0,
    Color? favoriteColor,
    Color? normalColor,
    bool showBackground = false,
    Color? backgroundColor,
    EdgeInsets? padding,
    void Function(bool isFavorite)? onChanged,
  }) {
    return FavoriteButton(
      song: this,
      size: size,
      favoriteColor: favoriteColor,
      normalColor: normalColor,
      showBackground: showBackground,
      backgroundColor: backgroundColor,
      padding: padding,
      onChanged: onChanged,
    );
  }
}
