import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/nearby_share_service.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../components/song_artwork.dart';

class NearbySharePage extends StatefulWidget {
  const NearbySharePage({super.key});

  @override
  State<NearbySharePage> createState() => _NearbySharePageState();
}

class _NearbySharePageState extends State<NearbySharePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final NearbyShareService _service = NearbyShareService();

  bool _permissionsGranted = false;
  bool _loading = false;
  String? _error;

  List<NearbyDevice> _devices = [];
  final List<NearbyTransferProgress> _transfers = [];
  StreamSubscription? _devicesSub;
  StreamSubscription? _progressSub;

  // Canciones seleccionadas para enviar
  final Set<String> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestPermissions();
    // Si se navega con arguments: 'bluetooth', saltar al tab Bluetooth (índice 2)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'bluetooth') {
        _tabController.animateTo(2);
      }
    });

    _devicesSub = _service.devicesStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });

    _progressSub = _service.progressStream.listen((progress) {
      if (!mounted) return;
      setState(() {
        final idx = _transfers.indexWhere(
          (t) => t.songTitle == progress.songTitle,
        );
        if (idx >= 0) {
          _transfers[idx] = progress;
        } else {
          _transfers.add(progress);
        }
      });

      if (progress.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${progress.songTitle}" recibida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (progress.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al transferir "${progress.songTitle}"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    _service.onConnectionRequest = (endpointId, name) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('📱 $name se conectó')));
      }
    };

    _service.onSongReceived = (title, filePath) {
      // Recargar la biblioteca para que aparezca la canción recibida
      if (mounted) {
        context.read<LibraryProvider>().loadLibrary();
      }
    };
  }

  Future<void> _requestPermissions() async {
    setState(() => _loading = true);
    final ok = await _service.requestPermissions();
    if (mounted) {
      setState(() {
        _permissionsGranted = ok;
        _loading = false;
        if (!ok) {
          _error =
              'Permisos requeridos no otorgados o GPS desactivado. Habilítalos en Ajustes.';
        }
      });
    }
  }

  Future<void> _startAdvertising() async {
    final user = context.read<AuthProvider>().currentUser;
    final name = user?.username ?? user?.firstName ?? 'AirPulse';
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await _service.startAdvertising(name);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) setState(() => _error = 'No se pudo iniciar el modo compartir.');
    }
  }

  Future<void> _startDiscovery() async {
    final user = context.read<AuthProvider>().currentUser;
    final name = user?.username ?? user?.firstName ?? 'AirPulse';
    setState(() {
      _loading = true;
      _error = null;
      _devices = [];
    });
    final ok = await _service.startDiscovery(name);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) setState(() => _error = 'No se pudo iniciar la búsqueda.');
    }
  }

  Future<void> _stop() async {
    await _service.stop();
    if (mounted) {
      setState(() {
        _devices = [];
      });
    }
  }

  Future<void> _shareViaBluetooth() async {
    final songs = context
        .read<LibraryProvider>()
        .songs
        .where((s) => _selectedSongIds.contains(s.id))
        .toList();
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una canción para enviar'),
        ),
      );
      return;
    }
    final files = songs.map((s) => XFile(s.filePath)).toList();
    await Share.shareXFiles(
      files,
      text: songs.length == 1
          ? 'Escucha "${songs.first.title}" en AirPulse'
          : '${songs.length} canciones de AirPulse',
    );
  }

  Future<void> _sendSongsToDevice(String endpointId) async {
    final songs = context
        .read<LibraryProvider>()
        .songs
        .where((s) => _selectedSongIds.contains(s.id))
        .toList();
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una canción para enviar'),
        ),
      );
      return;
    }
    for (final song in songs) {
      await _service.sendSong(endpointId, song);
    }
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _progressSub?.cancel();
    _service
        .dispose(); // async, pero dispose() no puede ser await; los streams ya se protegen internamente
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir por proximidad'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Enviar'),
            Tab(icon: Icon(Icons.download), text: 'Recibir'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
          ],
        ),
        actions: [
          if (_service.role != NearbyRole.idle)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Detener',
              onPressed: _stop,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) _ErrorBanner(error: _error!),
          if (!_permissionsGranted && !_loading)
            _PermissionsBanner(onRetry: _requestPermissions),
          if (_permissionsGranted)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SendTab(
                    role: _service.role,
                    devices: _devices,
                    selectedSongIds: _selectedSongIds,
                    onStartAdvertising: _startAdvertising,
                    onSendToDevice: _sendSongsToDevice,
                    onToggleSong: (id) {
                      setState(() {
                        if (_selectedSongIds.contains(id)) {
                          _selectedSongIds.remove(id);
                        } else {
                          _selectedSongIds.add(id);
                        }
                      });
                    },
                    onSelectAll: (allIds) {
                      setState(() {
                        if (_selectedSongIds.containsAll(allIds)) {
                          _selectedSongIds.removeAll(allIds);
                        } else {
                          _selectedSongIds.addAll(allIds);
                        }
                      });
                    },
                  ),
                  _ReceiveTab(
                    role: _service.role,
                    devices: _devices,
                    transfers: _transfers,
                    onStartDiscovery: _startDiscovery,
                    onConnectToDevice: (endpointId) =>
                        _service.connectToDevice(endpointId),
                  ),
                  _BluetoothTab(
                    selectedSongIds: _selectedSongIds,
                    onShareViaBluetooth: _shareViaBluetooth,
                    onToggleSong: (id) {
                      setState(() {
                        if (_selectedSongIds.contains(id)) {
                          _selectedSongIds.remove(id);
                        } else {
                          _selectedSongIds.add(id);
                        }
                      });
                    },
                    onSelectAll: (allIds) {
                      setState(() {
                        if (_selectedSongIds.containsAll(allIds)) {
                          _selectedSongIds.removeAll(allIds);
                        } else {
                          _selectedSongIds.addAll(allIds);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab Enviar ────────────────────────────────────────────────────────────────

class _SendTab extends StatelessWidget {
  final NearbyRole role;
  final List<NearbyDevice> devices;
  final Set<String> selectedSongIds;
  final VoidCallback onStartAdvertising;
  final Future<void> Function(String endpointId) onSendToDevice;
  final void Function(String songId) onToggleSong;
  final void Function(List<String> allIds) onSelectAll;

  const _SendTab({
    required this.role,
    required this.devices,
    required this.selectedSongIds,
    required this.onStartAdvertising,
    required this.onSendToDevice,
    required this.onToggleSong,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<LibraryProvider>().songs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrucción y botón
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.wifi_tethering,
                    size: 48,
                    color: Color(0xFFFF4D8B),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Modo compartir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role == NearbyRole.advertising
                        ? 'Esperando dispositivos cercanos…'
                        : 'Activa el modo para que otros dispositivos puedan conectarse.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (role != NearbyRole.advertising)
                    FilledButton.icon(
                      onPressed: onStartAdvertising,
                      icon: const Icon(Icons.share),
                      label: const Text('Activar modo compartir'),
                    ),
                  if (role == NearbyRole.advertising)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Buscando dispositivos…'),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Dispositivos cercanos (conectados y pendientes)
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Dispositivos cercanos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...devices.map(
              (device) => Card(
                child: ListTile(
                  leading: Icon(
                    device.connected ? Icons.smartphone : Icons.phone_android,
                    color: device.connected
                        ? const Color(0xFFFF4D8B)
                        : Colors.orange,
                  ),
                  title: Text(device.name),
                  subtitle: Text(
                    device.connected ? 'Conectado' : 'Conectando…',
                  ),
                  trailing: device.connected
                      ? FilledButton(
                          onPressed: selectedSongIds.isEmpty
                              ? null
                              : () => onSendToDevice(device.endpointId),
                          child: Text('Enviar (${selectedSongIds.length})'),
                        )
                      : const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ),
              ),
            ),
          ] else if (role == NearbyRole.advertising)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Esperando que otros dispositivos se conecten…'),
              ),
            ),

          // Lista de canciones para seleccionar
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleccionar canciones a enviar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: songs.isEmpty
                    ? null
                    : () => onSelectAll(songs.map((s) => s.id).toList()),
                child: Text(
                  selectedSongIds.length == songs.length ? 'Ninguna' : 'Todas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (songs.isEmpty)
            const Center(child: Text('No hay canciones en la biblioteca'))
          else
            ...songs.map(
              (song) => CheckboxListTile(
                value: selectedSongIds.contains(song.id),
                onChanged: (_) => onToggleSong(song.id),
                title: Text(song.title, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist, overflow: TextOverflow.ellipsis),
                secondary: SongArtwork(
                  songId: song.id,
                  artworkPath: song.artworkPath,
                  size: 40,
                  borderRadius: 6,
                  nullWidget: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.music_note, size: 20),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab Recibir ───────────────────────────────────────────────────────────────

class _ReceiveTab extends StatelessWidget {
  final NearbyRole role;
  final List<NearbyDevice> devices;
  final List<NearbyTransferProgress> transfers;
  final VoidCallback onStartDiscovery;
  final Future<bool> Function(String endpointId) onConnectToDevice;

  const _ReceiveTab({
    required this.role,
    required this.devices,
    required this.transfers,
    required this.onStartDiscovery,
    required this.onConnectToDevice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrucción y botón
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.search, size: 48, color: Color(0xFFFF4D8B)),
                  const SizedBox(height: 8),
                  const Text(
                    'Buscar dispositivos cercanos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role == NearbyRole.discovering
                        ? 'Buscando dispositivos con AirPulse…'
                        : 'Busca dispositivos cercanos que estén en modo compartir.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (role != NearbyRole.discovering)
                    FilledButton.icon(
                      onPressed: onStartDiscovery,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar dispositivos'),
                    ),
                  if (role == NearbyRole.discovering)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Buscando…'),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Dispositivos encontrados
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Dispositivos encontrados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...devices.map(
              (device) => Card(
                child: ListTile(
                  leading: Icon(
                    device.connected ? Icons.link : Icons.link_off,
                    color: device.connected
                        ? const Color(0xFFFF4D8B)
                        : Colors.grey,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.connected ? 'Conectado' : 'Disponible'),
                  trailing: device.connected
                      ? const Chip(label: Text('Listo'))
                      : OutlinedButton(
                          onPressed: () => onConnectToDevice(device.endpointId),
                          child: const Text('Conectar'),
                        ),
                ),
              ),
            ),
          ] else if (role == NearbyRole.discovering)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No se han encontrado dispositivos aún…'),
              ),
            ),

          // Transferencias en progreso / completadas
          if (transfers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Transferencias',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...transfers.map(
              (t) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            t.done
                                ? Icons.check_circle
                                : t.error
                                ? Icons.error
                                : Icons.download,
                            color: t.done
                                ? Colors.green
                                : t.error
                                ? Colors.red
                                : const Color(0xFFFF4D8B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.songTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            t.done
                                ? 'Completado'
                                : t.error
                                ? 'Error'
                                : '${(t.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: t.done
                                  ? Colors.green
                                  : t.error
                                  ? Colors.red
                                  : null,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (!t.done && !t.error) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: t.progress,
                          color: const Color(0xFFFF4D8B),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab Bluetooth clásico ─────────────────────────────────────────────────────

class _BluetoothTab extends StatelessWidget {
  final Set<String> selectedSongIds;
  final VoidCallback onShareViaBluetooth;
  final void Function(String songId) onToggleSong;
  final void Function(List<String> allIds) onSelectAll;

  const _BluetoothTab({
    required this.selectedSongIds,
    required this.onShareViaBluetooth,
    required this.onToggleSong,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<LibraryProvider>().songs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.bluetooth,
                    size: 52,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bluetooth clásico',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Envía archivos de audio a cualquier dispositivo con Bluetooth. '
                    'No requiere AirPulse en el receptor.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                    ),
                    onPressed: selectedSongIds.isEmpty
                        ? null
                        : onShareViaBluetooth,
                    icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
                    label: Text(
                      selectedSongIds.isEmpty
                          ? 'Selecciona canciones abajo'
                          : 'Enviar ${selectedSongIds.length} canción(es)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleccionar canciones',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: songs.isEmpty
                    ? null
                    : () => onSelectAll(songs.map((s) => s.id).toList()),
                child: Text(
                  selectedSongIds.length == songs.length ? 'Ninguna' : 'Todas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (songs.isEmpty)
            const Center(child: Text('No hay canciones en la biblioteca'))
          else
            ...songs.map(
              (song) => CheckboxListTile(
                value: selectedSongIds.contains(song.id),
                onChanged: (_) => onToggleSong(song.id),
                title: Text(song.title, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist, overflow: TextOverflow.ellipsis),
                secondary: SongArtwork(
                  songId: song.id,
                  artworkPath: song.artworkPath,
                  size: 40,
                  borderRadius: 6,
                  nullWidget: CircleAvatar(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.15),
                    child: const Icon(
                      Icons.music_note,
                      size: 20,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                activeColor: const Color(0xFF2196F3),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
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

class _PermissionsBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionsBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_disabled, size: 40),
          const SizedBox(height: 8),
          const Text(
            'Se requieren permisos de ubicación y Bluetooth para usar esta función.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Otorgar permisos'),
          ),
        ],
      ),
    );
  }
}
