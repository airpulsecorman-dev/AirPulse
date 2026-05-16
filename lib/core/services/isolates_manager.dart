/// 🚀 AirPulse Enterprise Isolates Manager
///
/// Sistema de gestión de isolates para operaciones CPU-intensivas.
///
/// Características:
/// - Pool de isolates reutilizables
/// - Task queue management
/// - Automatic load balancing
/// - Error handling y retry
/// - Progress tracking
///
/// Casos de uso:
/// - Escaneo de filesystem
/// - Lectura de metadata
/// - Procesamiento de imágenes
/// - Búsquedas en grandes datasets
/// - Transformaciones de datos
///
/// @author AirPulse Performance Team
/// @enterprise
/// @production
library;

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// Manager de isolates con pool reutilizable
class IsolatesManager {
  static final IsolatesManager _instance = IsolatesManager._internal();
  factory IsolatesManager() => _instance;
  IsolatesManager._internal();

  final List<_IsolateWorker> _workers = [];
  final int _maxWorkers = 4; // Número óptimo de isolates
  bool _initialized = false;

  /// Inicializa el pool de isolates
  Future<void> initialize() async {
    if (_initialized) return;

    for (int i = 0; i < _maxWorkers; i++) {
      final worker = _IsolateWorker(id: i);
      await worker.initialize();
      _workers.add(worker);
    }

    _initialized = true;
    debugPrint('[IsolatesManager] Pool inicializado con $_maxWorkers workers');
  }

  /// Ejecuta una tarea en un isolate disponible
  Future<R> run<T, R>(
    ComputeCallback<T, R> callback,
    T message, {
    String? debugLabel,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Encontrar worker menos ocupado
    final worker = _getLeastBusyWorker();

    try {
      return await worker.execute(callback, message, debugLabel: debugLabel);
    } catch (e) {
      debugPrint('[IsolatesManager] Error en tarea: $e');
      rethrow;
    }
  }

  /// Ejecuta múltiples tareas en paralelo
  Future<List<R>> runBatch<T, R>(
    ComputeCallback<T, R> callback,
    List<T> messages, {
    String? debugLabel,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final futures = <Future<R>>[];

    for (int i = 0; i < messages.length; i++) {
      final worker = _workers[i % _workers.length];
      futures.add(
        worker.execute(callback, messages[i], debugLabel: debugLabel),
      );
    }

    return Future.wait(futures);
  }

  /// Obtiene el worker con menos carga
  _IsolateWorker _getLeastBusyWorker() {
    return _workers.reduce((a, b) => a.pendingTasks < b.pendingTasks ? a : b);
  }

  /// Limpia recursos
  Future<void> dispose() async {
    for (final worker in _workers) {
      await worker.dispose();
    }
    _workers.clear();
    _initialized = false;
  }

  /// Métricas del pool
  IsolatesMetrics get metrics => IsolatesMetrics(
    totalWorkers: _workers.length,
    busyWorkers: _workers.where((w) => w.isBusy).length,
    totalTasksCompleted: _workers.fold(0, (sum, w) => sum + w.completedTasks),
    pendingTasks: _workers.fold(0, (sum, w) => sum + w.pendingTasks),
  );
}

/// Worker individual con su propio isolate
class _IsolateWorker {
  final int id;
  Isolate? _isolate;
  SendPort? _sendPort;
  final _responseMap = <int, Completer>{};
  int _nextId = 0;
  int _pendingTasks = 0;
  int _completedTasks = 0;

  _IsolateWorker({required this.id});

  int get pendingTasks => _pendingTasks;
  int get completedTasks => _completedTasks;
  bool get isBusy => _pendingTasks > 0;

  /// Inicializa el isolate
  Future<void> initialize() async {
    final receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      receivePort.sendPort,
      debugName: 'AirPulse-Worker-$id',
    );

    // Escuchar respuestas
    receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is _IsolateResponse) {
        final completer = _responseMap.remove(message.id);
        if (completer != null) {
          _pendingTasks--;
          _completedTasks++;

          if (message.error != null) {
            completer.completeError(message.error!);
          } else {
            completer.complete(message.result);
          }
        }
      }
    });

    // Esperar a que el isolate esté listo
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Ejecuta una tarea en este worker
  Future<R> execute<T, R>(
    ComputeCallback<T, R> callback,
    T message, {
    String? debugLabel,
  }) async {
    if (_sendPort == null) {
      throw StateError('Worker $id no inicializado');
    }

    final taskId = _nextId++;
    final completer = Completer<R>();
    _responseMap[taskId] = completer;
    _pendingTasks++;

    final request = _IsolateRequest(
      id: taskId,
      callback: callback,
      message: message,
      debugLabel: debugLabel,
    );

    _sendPort!.send(request);

    return completer.future;
  }

  /// Limpia recursos
  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _responseMap.clear();
  }

  /// Entry point del isolate
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is _IsolateRequest) {
        try {
          final result = await message.callback(message.message);
          sendPort.send(_IsolateResponse(id: message.id, result: result));
        } catch (e, stack) {
          sendPort.send(
            _IsolateResponse(id: message.id, error: e, stackTrace: stack),
          );
        }
      }
    });
  }
}

/// Request para el isolate
class _IsolateRequest<T, R> {
  final int id;
  final ComputeCallback<T, R> callback;
  final T message;
  final String? debugLabel;

  _IsolateRequest({
    required this.id,
    required this.callback,
    required this.message,
    this.debugLabel,
  });
}

/// Response del isolate
class _IsolateResponse {
  final int id;
  final dynamic result;
  final Object? error;
  final StackTrace? stackTrace;

  _IsolateResponse({
    required this.id,
    this.result,
    this.error,
    this.stackTrace,
  });
}

/// Métricas del pool de isolates
class IsolatesMetrics {
  final int totalWorkers;
  final int busyWorkers;
  final int totalTasksCompleted;
  final int pendingTasks;

  const IsolatesMetrics({
    required this.totalWorkers,
    required this.busyWorkers,
    required this.totalTasksCompleted,
    required this.pendingTasks,
  });

  double get efficiency {
    if (totalTasksCompleted == 0) return 0.0;
    return busyWorkers / totalWorkers;
  }

  @override
  String toString() =>
      '''
IsolatesMetrics(
  workers: $busyWorkers/$totalWorkers busy,
  tasks: $totalTasksCompleted completed, $pendingTasks pending,
  efficiency: ${(efficiency * 100).toStringAsFixed(1)}%
)''';
}
