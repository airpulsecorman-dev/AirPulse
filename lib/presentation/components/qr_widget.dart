import 'package:flutter/material.dart';
import '../../services/qr_service.dart';

class QRWidget extends StatelessWidget {
  final String payload;
  final String serverUrl;
  final int clientCount;

  const QRWidget({
    super.key,
    required this.payload,
    required this.serverUrl,
    required this.clientCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrService = QRService();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: qrService.buildQRWidget(payload: payload, size: 220),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Escanea con el navegador',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        SelectableText(
          serverUrl,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: const Icon(Icons.devices, size: 16),
          label: Text('$clientCount conectado${clientCount == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
