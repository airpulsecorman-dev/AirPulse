/// 🚀 AirPulse Debounce & Throttle Utilities
///
/// Optimización de eventos y callbacks para mejor rendimiento.
///
/// **Debounce**: Espera a que el usuario termine de escribir
/// **Throttle**: Limita la frecuencia de ejecución
///
/// Casos de uso:
/// - Búsquedas en tiempo real (debounce)
/// - Scroll events (throttle)
/// - Position updates (throttle)
/// - Resize/layout events (throttle)
///
/// @author AirPulse Performance Team
/// @enterprise
/// @production
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer para búsquedas y text input
class Debouncer {
  final Duration delay;
  Timer? _timer;
  VoidCallback? _action;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Ejecuta acción después del delay
  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      _action?.call();
      _action = null;
    });
  }

  /// Cancela ejecución pendiente
  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  /// Ejecuta inmediatamente
  void flush() {
    _timer?.cancel();
    _action?.call();
    _action = null;
  }

  void dispose() {
    cancel();
  }
}

/// Debouncer genérico con valor de retorno
class DebouncerWithValue<T> {
  final Duration delay;
  Timer? _timer;
  final void Function(T) callback;

  DebouncerWithValue({
    required this.callback,
    this.delay = const Duration(milliseconds: 300),
  });

  void call(T value) {
    _timer?.cancel();
    _timer = Timer(delay, () => callback(value));
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}

/// Throttler para limitar frecuencia de eventos
class Throttler {
  final Duration interval;
  Timer? _timer;
  bool _isReady = true;
  VoidCallback? _pendingAction;

  Throttler({this.interval = const Duration(milliseconds: 100)});

  /// Ejecuta acción respetando el intervalo
  void run(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();

      _timer = Timer(interval, () {
        _isReady = true;

        // Si hay acción pendiente, ejecutarla
        if (_pendingAction != null) {
          final pending = _pendingAction!;
          _pendingAction = null;
          run(pending);
        }
      });
    } else {
      // Guardar para ejecutar después
      _pendingAction = action;
    }
  }

  void cancel() {
    _timer?.cancel();
    _pendingAction = null;
    _isReady = true;
  }

  void dispose() {
    cancel();
  }
}

/// Stream throttler para streams de datos
class StreamThrottler<T> {
  final Duration interval;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  Timer? _timer;
  T? _lastValue;
  bool _hasValue = false;

  StreamThrottler({this.interval = const Duration(milliseconds: 100)});

  Stream<T> get stream => _controller.stream;

  void add(T value) {
    _lastValue = value;
    _hasValue = true;

    if (_timer == null || !_timer!.isActive) {
      _emitValue();
      _timer = Timer.periodic(interval, (_) {
        if (_hasValue) {
          _emitValue();
        }
      });
    }
  }

  void _emitValue() {
    if (_hasValue && _lastValue != null) {
      _controller.add(_lastValue as T);
      _hasValue = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Stream debouncer para streams de datos
class StreamDebouncer<T> {
  final Duration delay;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  Timer? _timer;

  StreamDebouncer({this.delay = const Duration(milliseconds: 300)});

  Stream<T> get stream => _controller.stream;

  void add(T value) {
    _timer?.cancel();
    _timer = Timer(delay, () => _controller.add(value));
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Extension para StreamController con debounce/throttle
extension StreamControllerExtension<T> on StreamController<T> {
  /// Transforma el stream con debounce
  Stream<T> debounce(Duration duration) {
    final debouncer = StreamDebouncer<T>(delay: duration);
    stream.listen(debouncer.add);
    return debouncer.stream;
  }

  /// Transforma el stream con throttle
  Stream<T> throttle(Duration duration) {
    final throttler = StreamThrottler<T>(interval: duration);
    stream.listen(throttler.add);
    return throttler.stream;
  }
}

/// Mixin para widgets que usan debounce/throttle
mixin DebounceMixin {
  final _debouncers = <String, Debouncer>{};

  Debouncer getDebouncer(String key, {Duration? delay}) {
    return _debouncers.putIfAbsent(
      key,
      () => Debouncer(delay: delay ?? const Duration(milliseconds: 300)),
    );
  }

  void disposeDebounce() {
    for (final debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    _debouncers.clear();
  }
}

mixin ThrottleMixin {
  final _throttlers = <String, Throttler>{};

  Throttler getThrottler(String key, {Duration? interval}) {
    return _throttlers.putIfAbsent(
      key,
      () => Throttler(interval: interval ?? const Duration(milliseconds: 100)),
    );
  }

  void disposeThrottle() {
    for (final throttler in _throttlers.values) {
      throttler.dispose();
    }
    _throttlers.clear();
  }
}
