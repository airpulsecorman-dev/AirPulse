import 'dart:async';

import 'package:airpulse/domain/coordinators/library_load_coordinator.dart';
import 'package:airpulse/domain/entities/library_load_result.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledCycleRunner implements LibraryLoadCycleRunner {
  final List<Completer<void>> _cycles = <Completer<void>>[];
  final Map<int, Completer<void>> _waiters = <int, Completer<void>>{};
  int cycleCount = 0;

  @override
  Future<void> runCycle() {
    cycleCount++;
    final completer = Completer<void>();
    _cycles.add(completer);
    final targets = _waiters.keys
        .where((target) => cycleCount >= target)
        .toList();
    for (final target in targets) {
      _waiters.remove(target)!.complete();
    }
    return completer.future;
  }

  Future<void> waitForCycleCount(int count) {
    if (cycleCount >= count) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiters[count] = completer;
    return completer.future;
  }

  void succeed(int cycleNumber) {
    _cycles[cycleNumber - 1].complete();
  }

  void fail(int cycleNumber, Object error, [StackTrace? stackTrace]) {
    _cycles[cycleNumber - 1].completeError(
      error,
      stackTrace ?? StackTrace.current,
    );
  }
}

void main() {
  group('LibraryLoadCoordinator', () {
    test('normal load succeeds', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      runner.succeed(1);

      final result = await future;
      expect(result.status, LibraryLoadResultStatus.success);
      expect(runner.cycleCount, 1);
    });

    test(
      'normal load converts runner exception to failed readException',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);
        final error = StateError('read failed');
        final stackTrace = StackTrace.current;

        final future = coordinator.load();
        await runner.waitForCycleCount(1);
        runner.fail(1, error, stackTrace);

        final result = await future;
        expect(result.status, LibraryLoadResultStatus.failed);
        expect(result.failureReason, LibraryLoadFailureReason.readException);
        expect(result.error, same(error));
        expect(result.stackTrace, same(stackTrace));
      },
    );

    test('two simultaneous normal loads share one cycle', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      final second = coordinator.load();
      await runner.waitForCycleCount(1);
      runner.succeed(1);

      final results = await Future.wait([first, second]);
      expect(runner.cycleCount, 1);
      expect(results[0].operationId, isNot(results[1].operationId));
      expect(results[0].cycleId, results[1].cycleId);
    });

    test(
      'normal load during normal load does not create another cycle',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        final second = coordinator.load();
        await runner.waitForCycleCount(1);
        runner.succeed(1);

        await Future.wait([first, second]);
        expect(runner.cycleCount, 1);
      },
    );

    test('normal load during refresh joins the refresh chain', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final refreshed = coordinator.refresh();
      await runner.waitForCycleCount(1);
      final loaded = coordinator.load();
      runner.succeed(1);

      final results = await Future.wait([refreshed, loaded]);
      expect(runner.cycleCount, 1);
      expect(results[0].cycleId, results[1].cycleId);
    });

    test('refresh during normal load schedules one repetition', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      final refreshed = coordinator.refresh();
      runner.succeed(1);
      await runner.waitForCycleCount(2);
      runner.succeed(2);

      await Future.wait([first, refreshed]);
      expect(runner.cycleCount, 2);
    });

    test('three refreshes during one cycle are consolidated', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      final refreshA = coordinator.refresh();
      final refreshB = coordinator.refresh();
      final refreshC = coordinator.refresh();
      runner.succeed(1);
      await runner.waitForCycleCount(2);
      runner.succeed(2);

      await Future.wait([first, refreshA, refreshB, refreshC]);
      expect(runner.cycleCount, 2);
    });

    test('refresh during repetition schedules exactly a third cycle', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      final pendingRefresh = coordinator.refresh();
      runner.succeed(1);
      await runner.waitForCycleCount(2);
      final thirdRefresh = coordinator.refresh();
      runner.succeed(2);
      await runner.waitForCycleCount(3);
      runner.succeed(3);

      await Future.wait([first, pendingRefresh, thirdRefresh]);
      expect(runner.cycleCount, 3);
    });

    test('new load after success starts an independent chain', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      runner.succeed(1);
      final firstResult = await first;

      final second = coordinator.load();
      await runner.waitForCycleCount(2);
      runner.succeed(2);
      final secondResult = await second;

      expect(firstResult.cycleId, isNot(secondResult.cycleId));
    });

    test('new load after failure starts an independent chain', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      runner.fail(1, StateError('first'));
      expect((await first).status, LibraryLoadResultStatus.failed);

      final second = coordinator.load();
      await runner.waitForCycleCount(2);
      runner.succeed(2);
      expect((await second).status, LibraryLoadResultStatus.success);
    });

    test(
      'failed then successful cycle resolves all operations as success',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        await runner.waitForCycleCount(1);
        final refresh = coordinator.refresh();
        runner.fail(1, StateError('intermediate'));
        await runner.waitForCycleCount(2);
        runner.succeed(2);

        final results = await Future.wait([first, refresh]);
        expect(
          results.every(
            (result) => result.status == LibraryLoadResultStatus.success,
          ),
          isTrue,
        );
        expect(results[0].cycleId, results[1].cycleId);
        expect(results[0].cycleId, isNot('cycle-1'));
      },
    );

    test(
      'two failed cycles resolve all operations with the final error',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        await runner.waitForCycleCount(1);
        final refresh = coordinator.refresh();
        final finalError = StateError('final');
        runner.fail(1, StateError('first'));
        await runner.waitForCycleCount(2);
        runner.fail(2, finalError);

        final results = await Future.wait([first, refresh]);
        for (final result in results) {
          expect(result.status, LibraryLoadResultStatus.failed);
          expect(result.error, same(finalError));
          expect(result.cycleId, 'cycle-2');
        }
      },
    );

    test(
      'successful then failed cycle resolves all operations as failed',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        await runner.waitForCycleCount(1);
        final refresh = coordinator.refresh();
        runner.succeed(1);
        await runner.waitForCycleCount(2);
        runner.fail(2, StateError('final failure'));

        final results = await Future.wait([first, refresh]);
        expect(
          results.every(
            (result) => result.status == LibraryLoadResultStatus.failed,
          ),
          isTrue,
        );
      },
    );

    test(
      'operation ids are unique and results are separate instances',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        final second = coordinator.load();
        await runner.waitForCycleCount(1);
        runner.succeed(1);

        final results = await Future.wait([first, second]);
        expect(results[0].operationId, isNot(results[1].operationId));
        expect(results[0], isNot(same(results[1])));
      },
    );

    test('dispose during first cycle cancels pending operations', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      coordinator.dispose();
      runner.succeed(1);

      final result = await future;
      expect(result.status, LibraryLoadResultStatus.cancelled);
      expect(coordinator.pendingOperationCount, 0);
    });

    test('dispose during a repetition cancels every operation', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      final refresh = coordinator.refresh();
      runner.succeed(1);
      await runner.waitForCycleCount(2);
      coordinator.dispose();

      final results = await Future.wait([first, refresh]);
      expect(
        results.every(
          (result) => result.status == LibraryLoadResultStatus.cancelled,
        ),
        isTrue,
      );
      expect(coordinator.pendingOperationCount, 0);
    });

    test(
      'dispose with refresh pending cancels without a third cycle',
      () async {
        final runner = ControlledCycleRunner();
        final coordinator = LibraryLoadCoordinator(runner: runner);

        final first = coordinator.load();
        await runner.waitForCycleCount(1);
        final refresh = coordinator.refresh();
        coordinator.dispose();
        runner.succeed(1);

        final results = await Future.wait([first, refresh]);
        expect(runner.cycleCount, 1);
        expect(
          results.every(
            (result) => result.status == LibraryLoadResultStatus.cancelled,
          ),
          isTrue,
        );
      },
    );

    test('calls after dispose return cancelled Futures immediately', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);
      coordinator.dispose();

      final loadResult = await coordinator.load();
      final refreshResult = await coordinator.refresh();

      expect(loadResult.status, LibraryLoadResultStatus.cancelled);
      expect(refreshResult.status, LibraryLoadResultStatus.cancelled);
      expect(loadResult.operationId, isNot(refreshResult.operationId));
      expect(loadResult.cycleId, refreshResult.cycleId);
      expect(runner.cycleCount, 0);
    });

    test('cycle exceeding timeout resolves as failed readException', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(
        runner: runner,
        cycleTimeout: const Duration(milliseconds: 20),
      );

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final result = await future;
      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.failureReason, LibraryLoadFailureReason.readException);
      expect(result.error, isA<TimeoutException>());
      expect(result.errorMessage, contains('timed out'));
    });

    test('runner that never completes is bounded by timeout', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(
        runner: runner,
        cycleTimeout: const Duration(milliseconds: 20),
      );

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      final result = await future.timeout(const Duration(milliseconds: 100));
      expect(result.status, LibraryLoadResultStatus.failed);
      expect(coordinator.pendingOperationCount, 0);
    });

    test('late completion cannot overwrite timeout result', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(
        runner: runner,
        cycleTimeout: const Duration(milliseconds: 20),
      );

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      runner.succeed(1);

      final result = await future;
      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.error, isA<TimeoutException>());
    });

    test('late completion after dispose cannot write to a new chain', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final old = coordinator.load();
      await runner.waitForCycleCount(1);
      coordinator.dispose();
      runner.succeed(1);

      expect((await old).status, LibraryLoadResultStatus.cancelled);
      expect(coordinator.pendingOperationCount, 0);
    });

    test('refreshes have no duplicate execution', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final first = coordinator.load();
      await runner.waitForCycleCount(1);
      final refreshes = [
        coordinator.refresh(),
        coordinator.refresh(),
        coordinator.refresh(),
      ];
      runner.succeed(1);
      await runner.waitForCycleCount(2);
      runner.succeed(2);
      await Future.wait([first, ...refreshes]);

      expect(runner.cycleCount, 2);
    });

    test('terminal states leave no pending operations', () async {
      final runner = ControlledCycleRunner();
      final coordinator = LibraryLoadCoordinator(runner: runner);

      final future = coordinator.load();
      await runner.waitForCycleCount(1);
      runner.succeed(1);
      await future;

      expect(coordinator.pendingOperationCount, 0);
      expect(coordinator.isDisposed, isFalse);
    });
  });
}
