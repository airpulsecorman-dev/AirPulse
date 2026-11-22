import 'dart:async';

import '../entities/library_load_result.dart';

abstract class LibraryLoadCycleRunner {
  Future<void> runCycle();
}

abstract class LibraryLoadIdGenerator {
  String nextOperationId();
  String nextCycleId();
}

class MonotonicLibraryLoadIdGenerator implements LibraryLoadIdGenerator {
  int _operationNumber = 0;
  int _cycleNumber = 0;

  @override
  String nextOperationId() {
    _operationNumber++;
    return 'operation-$_operationNumber';
  }

  @override
  String nextCycleId() {
    _cycleNumber++;
    return 'cycle-$_cycleNumber';
  }
}

class LibraryLoadCoordinator {
  LibraryLoadCoordinator({
    required LibraryLoadCycleRunner runner,
    LibraryLoadIdGenerator? idGenerator,
    this.cycleTimeout = const Duration(seconds: 30),
  }) : _runner = runner,
       _idGenerator = idGenerator ?? MonotonicLibraryLoadIdGenerator();

  final LibraryLoadCycleRunner _runner;
  final LibraryLoadIdGenerator _idGenerator;
  final Duration cycleTimeout;

  int _generation = 0;
  bool _disposed = false;
  String? _lastCycleId;
  String? _disposedCycleId;
  _LibraryLoadChain? _activeChain;
  Timer? _cycleTimer;

  bool get isDisposed => _disposed;
  int get pendingOperationCount => _activeChain?.operations.length ?? 0;

  Future<LibraryLoadResult> load() => _registerOperation(refresh: false);

  Future<LibraryLoadResult> refresh() => _registerOperation(refresh: true);

  Future<LibraryLoadResult> _registerOperation({required bool refresh}) {
    final operationId = _idGenerator.nextOperationId();
    final completer = Completer<LibraryLoadResult>();

    if (_disposed) {
      completer.complete(
        LibraryLoadResult.cancelled(
          operationId: operationId,
          cycleId: _disposedCycleId ?? _idGenerator.nextCycleId(),
        ),
      );
      return completer.future;
    }

    final operation = _PendingLibraryLoadOperation(
      operationId: operationId,
      completer: completer,
    );

    var chain = _activeChain;
    if (chain == null) {
      final generation = ++_generation;
      chain = _LibraryLoadChain(generation: generation);
      _activeChain = chain;
      chain.operations.add(operation);
      _startCycle(chain);
    } else {
      chain.operations.add(operation);
      if (refresh) {
        chain.refreshPending = true;
      }
    }

    return completer.future;
  }

  void _startCycle(_LibraryLoadChain chain) {
    if (_disposed || !identical(_activeChain, chain)) {
      return;
    }

    final cycleId = _idGenerator.nextCycleId();
    final cycleGeneration = chain.generation;
    chain.activeCycleId = cycleId;
    chain.isRunning = true;
    _lastCycleId = cycleId;

    _cycleTimer?.cancel();
    if (cycleTimeout <= Duration.zero) {
      _cycleTimer = Timer(
        Duration.zero,
        () => _onCycleTimeout(chain, cycleGeneration, cycleId),
      );
    } else {
      _cycleTimer = Timer(
        cycleTimeout,
        () => _onCycleTimeout(chain, cycleGeneration, cycleId),
      );
    }

    Future<void> runnerFuture;
    try {
      runnerFuture = Future<void>.sync(_runner.runCycle);
    } catch (error, stackTrace) {
      runnerFuture = Future<void>.error(error, stackTrace);
    }

    runnerFuture.then<void>(
      (_) => _onCycleSuccess(chain, cycleGeneration, cycleId),
      onError: (Object error, StackTrace stackTrace) {
        _onCycleFailure(chain, cycleGeneration, cycleId, error, stackTrace);
      },
    );
  }

  void _onCycleSuccess(
    _LibraryLoadChain chain,
    int cycleGeneration,
    String cycleId,
  ) {
    _finishCycle(
      chain,
      cycleGeneration,
      cycleId,
      const _LibraryLoadCycleResult.success(),
    );
  }

  void _onCycleFailure(
    _LibraryLoadChain chain,
    int cycleGeneration,
    String cycleId,
    Object error,
    StackTrace stackTrace,
  ) {
    _finishCycle(
      chain,
      cycleGeneration,
      cycleId,
      _LibraryLoadCycleResult.failed(
        error: error,
        errorMessage: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  }

  void _onCycleTimeout(
    _LibraryLoadChain chain,
    int cycleGeneration,
    String cycleId,
  ) {
    final timeout = TimeoutException(
      'Library load cycle timed out after ${cycleTimeout.inMilliseconds}ms',
      cycleTimeout,
    );
    _finishCycle(
      chain,
      cycleGeneration,
      cycleId,
      _LibraryLoadCycleResult.failed(
        error: timeout,
        errorMessage: timeout.toString(),
        stackTrace: StackTrace.current,
      ),
    );
  }

  void _finishCycle(
    _LibraryLoadChain chain,
    int cycleGeneration,
    String cycleId,
    _LibraryLoadCycleResult result,
  ) {
    if (_disposed ||
        !identical(_activeChain, chain) ||
        chain.generation != cycleGeneration ||
        chain.activeCycleId != cycleId ||
        !chain.isRunning) {
      return;
    }

    _cycleTimer?.cancel();
    _cycleTimer = null;
    chain.isRunning = false;
    chain.lastCycleResult = result;

    if (chain.refreshPending) {
      chain.refreshPending = false;
      _startCycle(chain);
      return;
    }

    final terminalCycleId = cycleId;
    final operations = List<_PendingLibraryLoadOperation>.from(
      chain.operations,
    );
    chain.operations.clear();
    _activeChain = null;

    for (final operation in operations) {
      if (operation.completer.isCompleted) {
        continue;
      }

      if (result.isSuccess) {
        operation.completer.complete(
          LibraryLoadResult.success(
            operationId: operation.operationId,
            cycleId: terminalCycleId,
          ),
        );
      } else {
        operation.completer.complete(
          LibraryLoadResult.failed(
            operationId: operation.operationId,
            cycleId: terminalCycleId,
            failureReason: LibraryLoadFailureReason.readException,
            error: result.error,
            errorMessage: result.errorMessage,
            stackTrace: result.stackTrace,
          ),
        );
      }
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _generation++;
    _cycleTimer?.cancel();
    _cycleTimer = null;

    final chain = _activeChain;
    _disposedCycleId =
        chain?.activeCycleId ?? _lastCycleId ?? _idGenerator.nextCycleId();

    if (chain != null) {
      final operations = List<_PendingLibraryLoadOperation>.from(
        chain.operations,
      );
      chain.operations.clear();
      chain.refreshPending = false;
      chain.isRunning = false;

      for (final operation in operations) {
        if (!operation.completer.isCompleted) {
          operation.completer.complete(
            LibraryLoadResult.cancelled(
              operationId: operation.operationId,
              cycleId: _disposedCycleId!,
            ),
          );
        }
      }
    }

    _activeChain = null;
  }
}

class _PendingLibraryLoadOperation {
  _PendingLibraryLoadOperation({
    required this.operationId,
    required this.completer,
  });

  final String operationId;
  final Completer<LibraryLoadResult> completer;
}

class _LibraryLoadChain {
  _LibraryLoadChain({required this.generation});

  final int generation;
  final List<_PendingLibraryLoadOperation> operations =
      <_PendingLibraryLoadOperation>[];
  bool refreshPending = false;
  bool isRunning = false;
  String? activeCycleId;
  _LibraryLoadCycleResult? lastCycleResult;
}

class _LibraryLoadCycleResult {
  const _LibraryLoadCycleResult.success()
    : isSuccess = true,
      error = null,
      errorMessage = null,
      stackTrace = null;

  const _LibraryLoadCycleResult.failed({
    required this.error,
    required this.errorMessage,
    required this.stackTrace,
  }) : isSuccess = false;

  final bool isSuccess;
  final Object? error;
  final String? errorMessage;
  final StackTrace? stackTrace;
}
