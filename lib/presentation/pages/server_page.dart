import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                onStart: () => server.startServer(
                  songs: library.songs,
                  userId: context.read<AuthProvider>().currentUser?.id,
                ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('AirPulse - Móvil'),
        actions: [
          if (server.isRunning)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Detener servidor',
              onPressed: server.stopServer,
            ),
        ],
      ),
      body: const _QRScannerPage(),
    );
  }
}

// ── Modelo de dispositivo vinculado ──────────────────────────────────────────
class _LinkedDevice {
  final String id;
  final String name;
  final DateTime linkedAt;

  _LinkedDevice({required this.id, required this.name, required this.linkedAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'linkedAt': linkedAt.millisecondsSinceEpoch,
  };

  factory _LinkedDevice.fromJson(Map<String, dynamic> map) => _LinkedDevice(
    id: map['id'] as String,
    name: map['name'] as String? ?? 'AirPulse Web',
    linkedAt: DateTime.fromMillisecondsSinceEpoch(map['linkedAt'] as int),
  );
}

const _kLinkedDevicesKey = 'linked_web_devices';

/// Página de escaneo QR para conectar el móvil a un servidor AirPulse web.
class _QRScannerPage extends StatefulWidget {
  const _QRScannerPage();

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  List<_LinkedDevice> _linkedDevices = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedDevices();
  }

  Future<void> _loadLinkedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLinkedDevicesKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      setState(
        () => _linkedDevices = list.map(_LinkedDevice.fromJson).toList(),
      );
    } catch (_) {
      await prefs.remove(_kLinkedDevicesKey);
    }
  }

  Future<void> _saveLinkedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLinkedDevicesKey,
      jsonEncode(_linkedDevices.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _addLinkedDevice(String sessionId) async {
    final device = _LinkedDevice(
      id: sessionId,
      name: 'AirPulse Web',
      linkedAt: DateTime.now(),
    );
    setState(() => _linkedDevices.add(device));
    await _saveLinkedDevices();
  }

  Future<void> _removeLinkedDevice(_LinkedDevice device) async {
    setState(() => _linkedDevices.removeWhere((d) => d.id == device.id));
    await _saveLinkedDevices();
  }

  void _startScanning() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QRLinkPage(
          onSessionApproved: (sessionId) async {
            await _addLinkedDevice(sessionId);
          },
        ),
      ),
    ).then((_) => _loadLinkedDevices());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Vista principal: lista de dispositivos vinculados ──
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.devices, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Dispositivos vinculados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_linkedDevices.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_linkedDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  'No hay dispositivos web vinculados todavía.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _linkedDevices.length,
                  itemBuilder: (context, index) {
                    final device = _linkedDevices[index];
                    return _DeviceTile(
                      device: device,
                      onUnlink: () => _confirmUnlink(device),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Vincular dispositivo web'),
                  onPressed: _startScanning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnlink(_LinkedDevice device) async {
    final serverProvider = context.read<ServerProvider>();
    final connectedCount = serverProvider.connectedClients.length;
    final isLastDevice = connectedCount <= 1;

    // Mensaje adaptado según cuántos clientes estén conectados
    final contentText = isLastDevice
        ? '¿Deseas desvincular "${device.name}"?\nEl servidor se detendrá ya que no quedan más dispositivos conectados.'
        : '¿Deseas desvincular "${device.name}"?\nEl servidor seguirá activo porque hay otros $connectedCount dispositivos conectados.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desvincular dispositivo'),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Enviar comando de desconexión al dispositivo web/desktop via RTDB
    await QrSessionService().sendDisconnectCommand(device.id);

    // Detener el servidor solo si era el único dispositivo conectado
    if (isLastDevice && serverProvider.isRunning) {
      await serverProvider.stopServer();
    }

    await _removeLinkedDevice(device);

    if (mounted && !isLastDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dispositivo desvinculado. El servidor sigue activo para los demás dispositivos.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

// ── Página independiente de escaneo QR para vincular dispositivo ─────────────
class _QRLinkPage extends StatefulWidget {
  final Future<void> Function(String sessionId) onSessionApproved;

  const _QRLinkPage({required this.onSessionApproved});

  @override
  State<_QRLinkPage> createState() => _QRLinkPageState();
}

class _QRLinkPageState extends State<_QRLinkPage> {
  MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  String? _connectedUrl;
  bool _isConnecting = false;
  String? _connectError;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _connectedUrl = null;
      _isConnecting = false;
      _connectError = null;
    });
    _scanner = MobileScannerController();
    _scanner.start();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // ── Flujo 1: QR de autenticación web (WhatsApp Web via RTDB) ──
    if (raw.startsWith('{')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['type'] == 'airpulse_web_auth') {
          final sessionId = map['sessionId'] as String?;
          if (sessionId == null || sessionId.isEmpty) return;

          setState(() {
            _scanned = true;
            _isConnecting = true;
            _connectError = null;
          });
          _scanner.stop();

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

            // Arrancar servidor ANTES de aprobar para que la URL ya esté
            // disponible cuando la web reciba el estado "approved".
            final serverProvider = context.read<ServerProvider>();
            final libraryProvider = context.read<LibraryProvider>();
            if (!serverProvider.isRunning) {
              await serverProvider.startServer(
                songs: libraryProvider.songs,
                userId: user.id,
              );
            }

            // Solo enviar serverUrl si es HTTPS (ngrok).
            // La IP local causa Mixed Content en la web HTTPS (GitHub Pages).
            final rawUrl = serverProvider.session?.publicUrl;
            final serverUrl = (rawUrl != null && rawUrl.startsWith('https://'))
                ? rawUrl
                : null;

            // Advertir al usuario si ngrok no pudo abrir el túnel HTTPS.
            // La sesión se aprueba igual, pero la web no podrá conectar al servidor.
            if (serverUrl == null &&
                serverProvider.ngrokError != null &&
                context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Túnel ngrok no disponible: ${serverProvider.ngrokError}\n'
                    'La web no podrá conectar al servidor.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 6),
                ),
              );
            }

            await service.approveWebSession(
              sessionId,
              user,
              serverUrl: serverUrl,
            );
            await Future.delayed(const Duration(seconds: 2));
            await service.deleteSession(sessionId);
            await widget.onSessionApproved(sessionId);

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
      } catch (_) {}
    }

    // ── Flujo 2: QR con URL del servidor web ──
    if (!raw.startsWith('http')) return;
    final webUrl = raw.split('?').first;

    setState(() {
      _scanned = true;
      _connectedUrl = webUrl;
      _isConnecting = true;
      _connectError = null;
    });
    _scanner.stop();

    try {
      final serverProvider = context.read<ServerProvider>();
      final libraryProvider = context.read<LibraryProvider>();
      final authProvider = context.read<AuthProvider>();
      await serverProvider.startServer(
        songs: libraryProvider.songs,
        userId: authProvider.currentUser?.id,
      );

      final mobileServerUrl = serverProvider.serverUrl;
      if (mobileServerUrl == null) {
        setState(() {
          _connectError = 'No se pudo iniciar el servidor';
          _isConnecting = false;
        });
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_scanned && _isConnecting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vinculando…')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF4D8B)),
              const SizedBox(height: 16),
              Text(
                _connectedUrl?.startsWith('web_auth:') == true
                    ? 'Aprobando sesión web…'
                    : 'Iniciando servidor y abriendo la web…',
              ),
            ],
          ),
        ),
      );
    }

    if (_scanned && _connectError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: _ErrorConnectView(error: _connectError!, onRetry: _reset),
      );
    }

    if (_scanned && _connectedUrl?.startsWith('web_auth:') == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispositivo vinculado')),
        body: _WebAuthApprovedView(onRescan: () => Navigator.pop(context)),
      );
    }

    if (_scanned) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conectado')),
        body: _ConnectedView(url: _connectedUrl!, onRescan: _reset),
      );
    }

    // Vista del escáner
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular dispositivo web'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _scanner.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(controller: _scanner, onDetect: _onDetect),
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
                    'Abre AirPulse web, ve al panel de conexión y escanea el QR que aparece en pantalla.',
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

class _DeviceTile extends StatelessWidget {
  final _LinkedDevice device;
  final VoidCallback onUnlink;

  const _DeviceTile({required this.device, required this.onUnlink});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.computer,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Vinculado: ${_formatDate(device.linkedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.link_off, color: Colors.redAccent),
          tooltip: 'Desvincular',
          onPressed: onUnlink,
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
