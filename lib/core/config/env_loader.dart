import 'package:flutter/services.dart';

/// Carga las variables de entorno desde assets/env.txt en tiempo de ejecución.
/// Esto permite usar valores reales tanto en debug como en release sin
/// necesidad de --dart-define.
class EnvLoader {
  static final Map<String, String> _env = {};

  static Future<void> load() async {
    try {
      final content = await rootBundle.loadString('assets/env.txt');
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final idx = trimmed.indexOf('=');
        if (idx == -1) continue;
        final key = trimmed.substring(0, idx).trim();
        final value = trimmed.substring(idx + 1).trim();
        _env[key] = value;
      }
    } catch (_) {
      // No se pudo cargar el archivo de entorno
    }
  }

  static String get(String key, {String defaultValue = ''}) {
    return _env[key] ?? defaultValue;
  }
}
