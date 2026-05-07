import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Muestra la URL del servidor local (http://IP:8765) embebida como WebView.
///
/// En plataformas móviles usa el WebView nativo.
/// En web (browser) usa un <iframe> — funciona si el esquema coincide
/// (ambos http:// o ambos https://). Desde GitHub Pages (https://)
/// el browser bloqueará la carga de http:// por Mixed Content.
class ServerWebViewPage extends StatefulWidget {
  final String serverUrl;
  const ServerWebViewPage({super.key, required this.serverUrl});

  @override
  State<ServerWebViewPage> createState() => _ServerWebViewPageState();
}

class _ServerWebViewPageState extends State<ServerWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.serverUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serverUrl,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: () async {
              final uri = Uri.parse(widget.serverUrl);
              // ignore: deprecated_member_use
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            _ErrorView(
              url: widget.serverUrl,
              onRetry: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String url;
  final VoidCallback onRetry;
  const _ErrorView({required this.url, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isHttpFromHttps =
        url.startsWith('http://') &&
        Uri.base.scheme == 'https';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              isHttpFromHttps
                  ? 'Bloqueado por Mixed Content'
                  : 'No se pudo conectar al servidor',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isHttpFromHttps
                  ? 'Los navegadores bloquean contenido HTTP dentro de páginas HTTPS.\n'
                    'Abre el servidor directamente en una nueva pestaña.'
                  : 'Verifica que el servidor esté activo en:\n$url',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
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
