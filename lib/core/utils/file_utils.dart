import 'dart:io';

/// Retorna la extensión de un archivo en minúsculas.
String fileExtension(String path) => path.split('.').last.toLowerCase();

/// Verifica si un archivo de audio es soportado.
bool isSupportedAudio(String path) {
  const supported = {'mp3', 'flac', 'aac', 'ogg', 'wav', 'm4a', 'opus'};
  return supported.contains(fileExtension(path));
}

/// Tamaño de archivo legible (KB, MB).
String readableFileSize(String path) {
  final file = File(path);
  if (!file.existsSync()) return '—';
  final bytes = file.lengthSync();
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
}
