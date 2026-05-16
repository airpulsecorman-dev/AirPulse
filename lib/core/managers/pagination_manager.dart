/// 📄 AirPulse Pagination Manager
///
/// Sistema empresarial de paginación y lazy loading para listas grandes.
///
/// Características:
/// - Lazy loading automático
/// - Infinite scroll support
/// - Prefetching inteligente
/// - Memory-efficient
/// - Customizable page sizes
///
/// @author AirPulse Performance Team
/// @enterprise
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manager de paginación para listas grandes
class PaginationManager<T> extends ChangeNotifier {
  final List<T> _allItems;
  final int pageSize;
  final int prefetchThreshold;

  List<T> _loadedItems = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  PaginationManager({
    required List<T> items,
    this.pageSize = 50,
    this.prefetchThreshold = 10,
  }) : _allItems = items {
    _loadInitialPage();
  }

  /// Items actualmente cargados
  List<T> get items => _loadedItems;

  /// Está cargando más items
  bool get isLoading => _isLoading;

  /// Hay más items por cargar
  bool get hasMore => _hasMore;

  /// Total de items disponibles
  int get totalItems => _allItems.length;

  /// Items cargados actualmente
  int get loadedCount => _loadedItems.length;

  /// Progreso de carga (0.0 - 1.0)
  double get loadProgress =>
      _allItems.isEmpty ? 1.0 : _loadedItems.length / _allItems.length;

  /// Carga página inicial
  void _loadInitialPage() {
    _loadedItems = _allItems.take(pageSize).toList();
    _currentPage = 1;
    _hasMore = _loadedItems.length < _allItems.length;
    notifyListeners();
  }

  /// Carga siguiente página
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    // Simular async load (para no bloquear UI)
    await Future.delayed(const Duration(milliseconds: 16));

    final start = _currentPage * pageSize;
    final end = (start + pageSize).clamp(0, _allItems.length);

    if (start < _allItems.length) {
      _loadedItems.addAll(_allItems.sublist(start, end));
      _currentPage++;
      _hasMore = end < _allItems.length;
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verifica si debe cargar más items basado en el índice actual
  void checkPrefetch(int currentIndex) {
    if (_loadedItems.isEmpty) return;

    final distanceToEnd = _loadedItems.length - currentIndex;
    if (distanceToEnd <= prefetchThreshold && !_isLoading && _hasMore) {
      loadMore();
    }
  }

  /// Resetea la paginación
  void reset() {
    _currentPage = 0;
    _loadedItems.clear();
    _isLoading = false;
    _hasMore = true;
    _loadInitialPage();
  }

  /// Actualiza todos los items y resetea
  void updateItems(List<T> newItems) {
    _allItems
      ..clear()
      ..addAll(newItems);
    reset();
  }

  @override
  void dispose() {
    _loadedItems.clear();
    super.dispose();
  }
}

/// Extension para fácil integración con ListView.builder
extension PaginationListView on PaginationManager {
  /// Widget builder helper para ListView
  Widget? buildLoadingIndicator() {
    if (!isLoading) return null;
    return const SizedBox(
      height: 60,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
