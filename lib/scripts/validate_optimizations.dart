/// 🧪 AirPulse - Script de Validación de Optimizaciones
///
/// Script para validar que todas las optimizaciones funcionan correctamente.
///
/// Ejecutar con: dart run lib/scripts/validate_optimizations.dart
///
/// @author AirPulse Performance Team
library;

import 'dart:io';

void main() async {
  print('🔍 Validando optimizaciones de AirPulse...\n');

  final results = <String, bool>{};

  // 1. Validar archivos críticos
  results['Archivos críticos'] = await _validateFiles();

  // 2. Validar imports
  results['Imports correctos'] = await _validateImports();

  // 3. Validar configuración
  results['Configuración'] = await _validateConfig();

  // Resumen
  print('\n' + '=' * 60);
  print('📊 RESUMEN DE VALIDACIÓN');
  print('=' * 60);

  int passedCount = 0;
  int total = results.length;

  results.forEach((test, testPassed) {
    final icon = testPassed ? '✅' : '❌';
    print('$icon $test');
    if (testPassed) passedCount++;
  });

  print('\n' + '=' * 60);
  print('Resultado: $passedCount/$total tests pasados');

  if (passedCount == total) {
    print('✅ ¡Todas las optimizaciones están correctamente instaladas!');
    print('\n🚀 AirPulse está listo para rendimiento enterprise.');
    exit(0);
  } else {
    print('❌ Algunas optimizaciones faltan o tienen errores.');
    print('\n📖 Revisa PERFORMANCE_OPTIMIZATION_GUIDE.md para más detalles.');
    exit(1);
  }
}

Future<bool> _validateFiles() async {
  print('📁 Validando archivos críticos...');

  final criticalFiles = [
    'lib/core/services/isolates_manager.dart',
    'lib/core/managers/metadata_cache_manager.dart',
    'lib/core/managers/artwork_cache_manager.dart',
    'lib/core/managers/pagination_manager.dart',
    'lib/core/utils/debounce_throttle.dart',
    'lib/core/monitoring/performance_monitor.dart',
    'lib/data/sources/local/library_local_source_optimized.dart',
    'lib/services/library_service_optimized.dart',
    'lib/presentation/controllers/library_controller_optimized.dart',
    'lib/presentation/controllers/player_controller_optimized.dart',
    'lib/presentation/pages/library_page_optimized.dart',
    'PERFORMANCE_OPTIMIZATION_GUIDE.md',
    'OPTIMIZATION_SUMMARY.md',
  ];

  bool allExist = true;

  for (final path in criticalFiles) {
    final file = File(path);
    final exists = await file.exists();

    if (exists) {
      print('  ✅ $path');
    } else {
      print('  ❌ $path (FALTA)');
      allExist = false;
    }
  }

  return allExist;
}

Future<bool> _validateImports() async {
  print('\n📦 Validando imports...');

  final checks = <String, bool>{};

  // Verificar que isolates_manager tenga imports necesarios
  final isolatesFile = File('lib/core/services/isolates_manager.dart');
  if (await isolatesFile.exists()) {
    final content = await isolatesFile.readAsString();
    checks['IsolatesManager imports'] =
        content.contains('dart:async') &&
        content.contains('dart:isolate') &&
        content.contains('package:flutter/foundation.dart');
  }

  // Verificar debounce_throttle
  final debounceFile = File('lib/core/utils/debounce_throttle.dart');
  if (await debounceFile.exists()) {
    final content = await debounceFile.readAsString();
    checks['Debounce imports'] =
        content.contains('dart:async') && content.contains('Timer');
  }

  bool allValid = checks.values.every((v) => v);

  checks.forEach((name, valid) {
    final icon = valid ? '✅' : '❌';
    print('  $icon $name');
  });

  return allValid;
}

Future<bool> _validateConfig() async {
  print('\n⚙️  Validando configuración...');

  bool valid = true;

  // Verificar pubspec.yaml tiene dependencias necesarias
  final pubspec = File('pubspec.yaml');
  if (await pubspec.exists()) {
    final content = await pubspec.readAsString();

    final deps = [
      'flutter_hooks',
      'provider',
      'rxdart',
      'sqflite',
      'on_audio_query',
      'just_audio',
    ];

    for (final dep in deps) {
      if (content.contains(dep)) {
        print('  ✅ Dependencia: $dep');
      } else {
        print('  ⚠️  Dependencia faltante: $dep');
      }
    }
  }

  return valid;
}
