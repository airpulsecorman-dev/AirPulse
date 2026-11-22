import 'package:flutter/foundation.dart';

enum LibraryLoadResultStatus { success, failed, cancelled }

enum LibraryLoadFailureReason { permissionDenied, readException }

@immutable
class LibraryLoadResult {
  final String operationId;
  final String cycleId;
  final LibraryLoadResultStatus status;
  final LibraryLoadFailureReason? failureReason;
  final Object? error;
  final String? errorMessage;
  final StackTrace? stackTrace;

  factory LibraryLoadResult({
    required String operationId,
    required String cycleId,
    required LibraryLoadResultStatus status,
    LibraryLoadFailureReason? failureReason,
    Object? error,
    String? errorMessage,
    StackTrace? stackTrace,
  }) {
    if (operationId.trim().isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Must not be empty',
      );
    }
    if (cycleId.trim().isEmpty) {
      throw ArgumentError.value(cycleId, 'cycleId', 'Must not be empty');
    }
    if (status == LibraryLoadResultStatus.success) {
      if (failureReason != null) {
        throw ArgumentError(
          'A successful library load cannot have a failureReason',
        );
      }
      if (error != null) {
        throw ArgumentError('A successful library load cannot have an error');
      }
      if (errorMessage != null) {
        throw ArgumentError(
          'A successful library load cannot have an errorMessage',
        );
      }
      if (stackTrace != null) {
        throw ArgumentError(
          'A successful library load cannot have a stackTrace',
        );
      }
    }
    if (status == LibraryLoadResultStatus.cancelled) {
      if (failureReason != null) {
        throw ArgumentError(
          'A cancelled library load cannot have a failureReason',
        );
      }
      if (error != null) {
        throw ArgumentError('A cancelled library load cannot have an error');
      }
      if (errorMessage != null) {
        throw ArgumentError(
          'A cancelled library load cannot have an errorMessage',
        );
      }
      if (stackTrace != null) {
        throw ArgumentError(
          'A cancelled library load cannot have a stackTrace',
        );
      }
    }
    if (status == LibraryLoadResultStatus.failed && failureReason == null) {
      throw ArgumentError('A failed library load must have a failureReason');
    }

    return LibraryLoadResult._(
      operationId: operationId,
      cycleId: cycleId,
      status: status,
      failureReason: failureReason,
      error: error,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );
  }

  const LibraryLoadResult._({
    required this.operationId,
    required this.cycleId,
    required this.status,
    this.failureReason,
    this.error,
    this.errorMessage,
    this.stackTrace,
  });

  factory LibraryLoadResult.success({
    required String operationId,
    required String cycleId,
  }) {
    return LibraryLoadResult(
      operationId: operationId,
      cycleId: cycleId,
      status: LibraryLoadResultStatus.success,
    );
  }

  factory LibraryLoadResult.failed({
    required String operationId,
    required String cycleId,
    required LibraryLoadFailureReason failureReason,
    Object? error,
    String? errorMessage,
    StackTrace? stackTrace,
  }) {
    return LibraryLoadResult(
      operationId: operationId,
      cycleId: cycleId,
      status: LibraryLoadResultStatus.failed,
      failureReason: failureReason,
      error: error,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );
  }

  factory LibraryLoadResult.cancelled({
    required String operationId,
    required String cycleId,
  }) {
    return LibraryLoadResult(
      operationId: operationId,
      cycleId: cycleId,
      status: LibraryLoadResultStatus.cancelled,
    );
  }
}
