/// Formatea una [Duration] como mm:ss o h:mm:ss.
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Calcula el progreso normalizado (0.0 – 1.0) de la reproducción.
double playbackProgress(Duration position, Duration total) {
  if (total.inMilliseconds == 0) return 0.0;
  return (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
}
