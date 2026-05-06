import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../hooks/use_server.dart';
import '../hooks/use_library.dart';
import '../providers/server_provider.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../components/qr_widget.dart';
import '../../services/qr_session_service.dart';

class ServerPage extends HookWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final server = useServer(context);
    final library = useLibrary(context);

    // En móvil (Android/iOS): mostrar servidor local para que la web se conecte
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      return _MobileServerPage();
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
            if (server.error != null) _ErrorBanner(error: server.error!),
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

/// Página de servidor para móvil: inicia el servidor local y muestra el QR
/// para que la web se conecte y use las canciones del móvil.
class _MobileServerPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final server = useServer(context);
    final library = useLibrary(context);
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AirPulse - Móvil'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wifi_tethering), text: 'Compartir música'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear web'),
          ],
        ),
        actions: [
          if (server.isRunning)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Detener servidor',
              onPressed: server.stopServer,
            ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // TAB 1: Iniciar servidor para compartir canciones a la web
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (server.error != null) _ErrorBanner(error: server.error!),
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
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cómo conectar desde la web',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '1. Abre AirPulse en el navegador web.\n'
                                    '2. En la pantalla de inicio de sesión ingresa la URL de abajo.\n'
                                    '3. Toca "Conectar" para ver y reproducir tus canciones desde la web.',
                                    style: TextStyle(height: 1.6),
                                  ),
                                  const SizedBox(height: 12),
                                  if (server.serverUrl != null)
                                    SelectableText(
                                      server.serverUrl!,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // TAB 2: Escanear QR de la web para conectarse como cliente
          const _QRScannerPage(),
        ],
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
  MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;
  String? _connectedUrl;
  bool _isConnecting = false;
  String? _connectError;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // ── Flujo 1: QR de autenticación web (estilo WhatsApp Web via RTDB) ──
    if (raw.startsWith('{')) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['type'] == 'airpulse_web_auth') {
          final sessionId = json['sessionId'] as String?;
          if (sessionId == null || sessionId.isEmpty) return;

          setState(() {
            _scanned = true;
            _isConnecting = true;
            _connectError = null;
          });
          _scannerController.stop();

          try {
            final auth = context.read<AuthProvider>();
            final user = auth.currentUser;
            if (user == null) {
              setState(() {
                _connectError = 'Debes iniciar sesión en el móvil primero';
                _isConnecting = false;
              });
              return;
            }

            final service = QrSessionService();
            await service.approveWebSession(sessionId, user);

            setState(() {
              _connectedUrl = 'web_auth:$sessionId';
              _isConnecting = false;
            });
          } catch (e) {
            setState(() {
              _connectError = 'Error al aprobar sesión: $e';
              _isConnecting = false;
            });
          }
          return;
        }
      } catch (_) {
        // No es JSON válido, continuar con el flujo normal
      }
    }

    // ── Flujo 2: QR con URL del servidor web (flujo anterior) ──
    String? webUrl;
    if (raw.startsWith('http')) {
      webUrl = raw.split('?').first;
    } else {
      return;
    }

    setState(() {
      _scanned = true;
      _connectedUrl = webUrl;
      _isConnecting = true;
      _connectError = null;
    });
    _scannerController.stop();

    try {
      // 1. Iniciar el servidor móvil
      final serverProvider = context.read<ServerProvider>();
      final libraryProvider = context.read<LibraryProvider>();
      await serverProvider.startServer(songs: libraryProvider.songs);

      final mobileServerUrl = serverProvider.serverUrl;
      if (mobileServerUrl == null) {
        setState(() {
          _connectError = 'No se pudo iniciar el servidor';
          _isConnecting = false;
        });
        return;
      }

      // 2. Abrir la web con el parámetro serverUrl para auto-conectar
      final targetUri = Uri.parse(
        webUrl,
      ).replace(queryParameters: {'serverUrl': mobileServerUrl});
      await launchUrl(targetUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(() => _connectError = e.toString());
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _connectedUrl = null;
      _isConnecting = false;
      _connectError = null;
    });
    _scannerController = MobileScannerController();
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
          ? (_isConnecting
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFF4D8B),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _connectedUrl?.startsWith('web_auth:') == true
                              ? 'Aprobando sesión web…'
                              : 'Iniciando servidor y abriendo la web…',
                        ),
                      ],
                    ),
                  )
                : _connectError != null
                ? _ErrorConnectView(error: _connectError!, onRetry: _reset)
                : _connectedUrl?.startsWith('web_auth:') == true
                ? _WebAuthApprovedView(onRescan: _reset)
                : _ConnectedView(url: _connectedUrl!, onRescan: _reset))
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
                          'Abre AirPulse web, ve al panel de conexión y escanea el QR que aparece en la pantalla de la web.',
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
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              '¡Servidor iniciado!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La web se abre automáticamente con las canciones listas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              url,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Conectar otra web'),
              onPressed: onRescan,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorConnectView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorConnectView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al conectar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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

class _WebAuthApprovedView extends StatelessWidget {
  final VoidCallback onRescan;

  const _WebAuthApprovedView({required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Sesión web aprobada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'La web ya está iniciando sesión con tu cuenta.\nPuedes cerrar este diálogo.',
              style: TextStyle(color: Color(0xFF8899AA)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4D8B)),
                foregroundColor: const Color(0xFFFF4D8B),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear otro QR'),
              onPressed: onRescan,
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
            Text(
              'Cómo conectarse:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
