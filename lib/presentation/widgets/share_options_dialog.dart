import 'package:flutter/material.dart';
import '../../core/utils/Colors.dart';

/// Muestra un diálogo con las tres opciones de compartir.
/// [selectedSongIds] — IDs de canciones ya seleccionadas (para Bluetooth).
Future<void> showShareOptionsDialog(
  BuildContext context, {
  Set<String> selectedSongIds = const {},
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _ShareOptionsDialog(selectedSongIds: selectedSongIds),
  );
}

class _ShareOptionsDialog extends StatelessWidget {
  final Set<String> selectedSongIds;

  const _ShareOptionsDialog({required this.selectedSongIds});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.share, color: AppColors.share),
          SizedBox(width: 8),
          Flexible(child: Text('Compartir música')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Opción 1: Servidor local ────────────────────────────────────
          _OptionTile(
            icon: Icons.wifi_tethering,
            iconColor: AppColors.whatsapp,
            title: 'Servidor local',
            subtitle:
                'Transmite toda la biblioteca por Wi-Fi a cualquier navegador en la misma red.',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/server');
            },
          ),
          const Divider(height: 1),

          // ── Opción 2: Compartir por proximidad ─────────────────────────
          _OptionTile(
            icon: Icons.bluetooth_searching,
            iconColor: AppColors.share,
            title: 'Compartir por proximidad',
            subtitle:
                'Envía canciones a otro dispositivo con AirPulse usando Bluetooth y Wi-Fi Direct.',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/nearby-share');
            },
          ),
          const Divider(height: 1),

          // ── Opción 3: Bluetooth clásico ────────────────────────────────
          _OptionTile(
            icon: Icons.bluetooth,
            iconColor: AppColors.nearby,
            title: 'Bluetooth clásico',
            subtitle:
                'Envía archivos a cualquier dispositivo con Bluetooth. Selecciona canciones primero.',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(
                context,
                '/nearby-share',
                arguments: 'bluetooth',
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
