import 'package:airpulse/domain/entities/library_load_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryLoadResult', () {
    test('constructs a success result', () {
      final result = LibraryLoadResult.success(
        operationId: 'operation-1',
        cycleId: 'cycle-1',
      );

      expect(result.status, LibraryLoadResultStatus.success);
      expect(result.failureReason, isNull);
      expect(result.error, isNull);
      expect(result.errorMessage, isNull);
      expect(result.stackTrace, isNull);
    });

    test('constructs a failed result with permissionDenied', () {
      final result = LibraryLoadResult.failed(
        operationId: 'operation-2',
        cycleId: 'cycle-2',
        failureReason: LibraryLoadFailureReason.permissionDenied,
      );

      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.failureReason, LibraryLoadFailureReason.permissionDenied);
    });

    test('constructs a failed result with readException', () {
      final originalError = StateError('Cannot read library');
      final stackTrace = StackTrace.current;
      final result = LibraryLoadResult.failed(
        operationId: 'operation-3',
        cycleId: 'cycle-3',
        failureReason: LibraryLoadFailureReason.readException,
        error: originalError,
        errorMessage: originalError.message,
        stackTrace: stackTrace,
      );

      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.failureReason, LibraryLoadFailureReason.readException);
      expect(result.error, same(originalError));
      expect(result.errorMessage, 'Cannot read library');
      expect(result.stackTrace, same(stackTrace));
    });

    test('constructs a cancelled result', () {
      final result = LibraryLoadResult.cancelled(
        operationId: 'operation-4',
        cycleId: 'cycle-4',
      );

      expect(result.status, LibraryLoadResultStatus.cancelled);
      expect(result.failureReason, isNull);
    });

    test('rejects invalid status and failure reason combinations', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-5',
          cycleId: 'cycle-5',
          status: LibraryLoadResultStatus.success,
          failureReason: LibraryLoadFailureReason.permissionDenied,
        ),
        throwsArgumentError,
      );
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-6',
          cycleId: 'cycle-6',
          status: LibraryLoadResultStatus.cancelled,
          failureReason: LibraryLoadFailureReason.readException,
        ),
        throwsArgumentError,
      );
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-7',
          cycleId: 'cycle-7',
          status: LibraryLoadResultStatus.failed,
        ),
        throwsArgumentError,
      );
    });

    test('success rejects error', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-success-error',
          cycleId: 'cycle-success-error',
          status: LibraryLoadResultStatus.success,
          error: StateError('Unexpected success error'),
        ),
        throwsArgumentError,
      );
    });

    test('success rejects errorMessage', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-success-message',
          cycleId: 'cycle-success-message',
          status: LibraryLoadResultStatus.success,
          errorMessage: 'Unexpected success message',
        ),
        throwsArgumentError,
      );
    });

    test('success rejects stackTrace', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-success-stack',
          cycleId: 'cycle-success-stack',
          status: LibraryLoadResultStatus.success,
          stackTrace: StackTrace.current,
        ),
        throwsArgumentError,
      );
    });

    test('cancelled rejects error', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-cancelled-error',
          cycleId: 'cycle-cancelled-error',
          status: LibraryLoadResultStatus.cancelled,
          error: StateError('Unexpected cancelled error'),
        ),
        throwsArgumentError,
      );
    });

    test('cancelled rejects errorMessage', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-cancelled-message',
          cycleId: 'cycle-cancelled-message',
          status: LibraryLoadResultStatus.cancelled,
          errorMessage: 'Unexpected cancelled message',
        ),
        throwsArgumentError,
      );
    });

    test('cancelled rejects stackTrace', () {
      expect(
        () => LibraryLoadResult(
          operationId: 'operation-cancelled-stack',
          cycleId: 'cycle-cancelled-stack',
          status: LibraryLoadResultStatus.cancelled,
          stackTrace: StackTrace.current,
        ),
        throwsArgumentError,
      );
    });

    test('failed permits no original exception', () {
      final result = LibraryLoadResult.failed(
        operationId: 'operation-failed-no-error',
        cycleId: 'cycle-failed-no-error',
        failureReason: LibraryLoadFailureReason.readException,
      );

      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.failureReason, LibraryLoadFailureReason.readException);
      expect(result.error, isNull);
      expect(result.errorMessage, isNull);
      expect(result.stackTrace, isNull);
    });

    test('failed permits optional errorMessage and stackTrace', () {
      final stackTrace = StackTrace.current;
      final result = LibraryLoadResult.failed(
        operationId: 'operation-failed-details',
        cycleId: 'cycle-failed-details',
        failureReason: LibraryLoadFailureReason.readException,
        errorMessage: 'Read failed',
        stackTrace: stackTrace,
      );

      expect(result.error, isNull);
      expect(result.errorMessage, 'Read failed');
      expect(result.stackTrace, same(stackTrace));
    });

    test('rejects empty operationId and cycleId', () {
      expect(
        () => LibraryLoadResult.success(operationId: '', cycleId: 'cycle-8'),
        throwsArgumentError,
      );
      expect(
        () =>
            LibraryLoadResult.success(operationId: 'operation-8', cycleId: ' '),
        throwsArgumentError,
      );
    });

    test('preserves operationId and cycleId', () {
      final result = LibraryLoadResult.success(
        operationId: 'operation-preserved',
        cycleId: 'cycle-preserved',
      );

      expect(result.operationId, 'operation-preserved');
      expect(result.cycleId, 'cycle-preserved');
    });

    test('exposes final immutable fields', () {
      final result = LibraryLoadResult.failed(
        operationId: 'operation-immutable',
        cycleId: 'cycle-immutable',
        failureReason: LibraryLoadFailureReason.permissionDenied,
        errorMessage: 'Denied',
      );

      expect(result.operationId, 'operation-immutable');
      expect(result.cycleId, 'cycle-immutable');
      expect(result.status, LibraryLoadResultStatus.failed);
      expect(result.failureReason, LibraryLoadFailureReason.permissionDenied);
      expect(result.errorMessage, 'Denied');
    });
  });
}
