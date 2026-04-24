import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../hooks/use_server.dart';
import '../hooks/use_library.dart';
import '../components/qr_widget.dart';

class ServerPage extends HookWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final server = useServer(context);
    final library = useLibrary(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servidor local'),
        actions: [
          if (server.isRunning)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Detener servidor',
              onPressed: server.stopServer,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (server.error != null)
              _ErrorBanner(error: server.error!),
            if (!server.isRunning && !server.isStarting)
              _StartServerCard(
                onStart: () => server.startServer(songs: library.songs),
              ),
            if (server.isStarting)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Iniciando servidor…'),
                  ],
                ),
              ),
            if (server.isRunning && server.qrPayload != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      QRWidget(
                        payload: server.qrPayload!,
                        serverUrl: server.serverUrl ?? '',
                        clientCount: server.connectedClients.length,
                      ),
                      const SizedBox(height: 24),
                      _InstructionCard(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartServerCard extends StatelessWidget {
  final VoidCallback onStart;
  const _StartServerCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.wifi_tethering, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Inicia el servidor para que los navegadores\nen la misma red puedan conectarse.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar servidor'),
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber),
          const SizedBox(width: 8),
          Expanded(child: Text(error)),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Cómo conectarse:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Conecta el navegador a la misma red WiFi'),
            Text('2. Escanea el QR con la cámara o abre la URL'),
            Text('3. La PWA cargará automáticamente la biblioteca'),
            Text('4. Puedes controlar la reproducción desde el navegador'),
          ],
        ),
      ),
    );
  }
}
