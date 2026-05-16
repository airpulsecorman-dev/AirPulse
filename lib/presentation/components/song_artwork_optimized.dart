/// 🎨 AirPulse Song Artwork - OPTIMIZADO
///
/// Widget optimizado para mostrar artwork de canciones con cache avanzado.
///
/// Optimizaciones implementadas:
/// - ArtworkCacheManager con LRU
/// - Preloading inteligente
/// - Placeholders optimizados
/// - RepaintBoundary
/// - Memory-efficient loading
/// - FadeIn transitions suaves
///
/// @author AirPulse Performance Team
/// @enterprise
/// @optimized
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/managers/artwork_cache_manager.dart';

/// Widget de artwork optimizado con cache
class SongArtworkOptimized extends StatefulWidget {
  final String songId;
  final String? artworkPath;
  final double size;
  final double borderRadius;
  final Widget? nullWidget;

  const SongArtworkOptimized({
    super.key,
    required this.songId,
    this.artworkPath,
    this.size = 48,
    this.borderRadius = 24,
    this.nullWidget,
  });

  @override
  State<SongArtworkOptimized> createState() => _SongArtworkOptimizedState();
}

class _SongArtworkOptimizedState extends State<SongArtworkOptimized>
    with AutomaticKeepAliveClientMixin {
  // 🚀 OPTIMIZACIÓN: Mantener estado durante scroll
  @override
  bool get wantKeepAlive => true;

  static final ArtworkCacheManager _cacheManager = ArtworkCacheManager();
  static bool _initialized = false;

  ImageProvider? _cachedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCacheManager();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(SongArtworkOptimized oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId ||
        oldWidget.artworkPath != widget.artworkPath) {
      _loadArtwork();
    }
  }

  void _initializeCacheManager() {
    if (!_initialized) {
      _cacheManager.initialize(
        maxImageCache: 100, // 100 imágenes decodificadas
        maxBytesCache: 500, // 500 artwork como bytes
      );
      _initialized = true;
    }
  }

  Future<void> _loadArtwork() async {
    // 🚀 OPTIMIZACIÓN: Verificar cache primero
    final cached = _cacheManager.getArtwork(widget.songId);
    if (cached != null) {
      if (mounted) {
        setState(() => _cachedImage = cached);
      }
      return;
    }

    // Si no hay path, no cargar
    if (widget.artworkPath == null) return;

    // Cargar en background
    if (!_isLoading) {
      _isLoading = true;
      await _cacheManager.preloadArtwork(widget.songId, widget.artworkPath);

      if (mounted) {
        final loaded = _cacheManager.getArtwork(widget.songId);
        setState(() {
          _cachedImage = loaded;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final fallback = widget.nullWidget ?? _buildDefaultFallback(context);

    // Web: mostrar fallback
    if (kIsWeb) {
      return RepaintBoundary(child: fallback);
    }

    // macOS: usar cache manager
    if (Platform.isMacOS) {
      return RepaintBoundary(child: _buildCachedImage(fallback));
    }

    // Android/iOS: usar QueryArtworkWidget con cache
    return RepaintBoundary(child: _buildAndroidArtwork(fallback));
  }

  /// 🚀 Build con imagen cacheada (macOS)
  Widget _buildCachedImage(Widget fallback) {
    if (_cachedImage == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image(
        image: _cachedImage!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;

          // 🚀 OPTIMIZACIÓN: FadeIn suave solo la primera vez
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
            child: child,
          );
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  /// 🚀 Build para Android/iOS con QueryArtworkWidget
  Widget _buildAndroidArtwork(Widget fallback) {
    final songIdInt = int.tryParse(widget.songId);
    if (songIdInt == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: QueryArtworkWidget(
        id: songIdInt,
        type: ArtworkType.AUDIO,
        artworkWidth: widget.size,
        artworkHeight: widget.size,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.circular(widget.borderRadius),
        keepOldArtwork:
            true, // 🚀 IMPORTANTE: mantener artwork durante transiciones
        nullArtworkWidget: fallback,
      ),
    );
  }

  /// Fallback por defecto
  Widget _buildDefaultFallback(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimaryContainer,
        size: widget.size * 0.5,
      ),
    );
  }
}
