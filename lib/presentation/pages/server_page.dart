import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../hooks/use_server.dart';
import '../hooks/use_library.dart';
import '../components/qr_widget.dart';

class ServerPage extends HookWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final server = useServer(context);
    final library = useLibrary(context);

    // En móvil (Android/iOS): mostrar escáner QR para conectarse a la web
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      return const _QRScannerPage();
    }

    // En desktop/web: flujo normal de servidor
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

/// Página de escaneo QR para conectar el móvil a un servidor AirPulse web.
class _QRScannerPage extends StatefulWidget {
  const _QRScannerPage();

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;
  String? _connectedUrl;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // Intentar parsear payload JSON de AirPulse
    String? url;
    try {
      final data = Map<String, dynamic>.from(
        (raw.startsWith('{'))
            ? (raw as dynamic)
            : throw FormatException('not json'),
      );
      if (data['type'] == 'airpulse_connect') {
        url = data['url'] as String?;
      }
    } catch (_) {
      // Si no es JSON, tratar el valor directo como URL
      if (raw.startsWith('http')) url = raw;
    }

    if (url == null) return;

    setState(() {
      _scanned = true;
      _connectedUrl = url;
    });
    _scannerController.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conectado a $url'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _connectedUrl = null;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar a AirPulse Web'),
        actions: [
          if (!_scanned)
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Linterna',
              onPressed: () => _scannerController.toggleTorch(),
            ),
          if (_scanned)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Escanear de nuevo',
              onPressed: _reset,
            ),
        ],
      ),
      body: _scanned
          ? _ConnectedView(url: _connectedUrl!, onRescan: _reset)
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      // Marco de guía
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.computer, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Abre la URL del servidor en tu PC o Smart TV y escanea el código QR que aparece en pantalla.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ConnectedView extends StatelessWidget {
  final String url;
  final VoidCallback onRescan;

  const _ConnectedView({required this.url, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('¡Conectado!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(url,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear otro servidor'),
              onPressed: onRescan,
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
