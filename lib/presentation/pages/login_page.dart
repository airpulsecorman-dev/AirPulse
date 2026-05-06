import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../../services/qr_session_service.dart';
import 'web_library_page.dart';
import 'google_onboarding_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    // Si la web se abrió con ?serverUrl= (enviado por el móvil tras escanear el QR),
    // auto-navegar directamente a WebLibraryPage.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final serverUrl = Uri.base.queryParameters['serverUrl'];
        if (serverUrl != null && serverUrl.isNotEmpty && mounted) {
          final normalized = serverUrl.endsWith('/')
              ? serverUrl.substring(0, serverUrl.length - 1)
              : serverUrl;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => WebLibraryPage(serverUrl: normalized),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al iniciar sesión'),
          backgroundColor: const Color(0xFFFF4D8B),
        ),
      );
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      final user = auth.currentUser;
      if (user != null && !user.acceptedTerms) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GoogleOnboardingPage()),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error con Google'),
          backgroundColor: const Color(0xFFFF4D8B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 64 : 32,
                  vertical: 32,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildBranding()),
                          const SizedBox(width: 48),
                          Expanded(child: _buildForm(auth)),
                          if (kIsWeb) ...[
                            const SizedBox(width: 48),
                            Expanded(child: _buildMobileConnectPanel(context)),
                          ],
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBranding(),
                          const SizedBox(height: 40),
                          _buildForm(auth),
                          if (kIsWeb) ...[
                            const SizedBox(height: 32),
                            _buildMobileConnectPanel(context),
                          ],
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A2D42),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8B).withValues(alpha: 0.4),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: 48,
            color: Color(0xFFFF4D8B),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AirPulse',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inicia sesión para continuar',
          style: TextStyle(color: Color(0xFF8899AA), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm(dynamic auth) {
    return Column(
      children: [
        // ── Google ────────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading ? null : _googleSignIn,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF334455)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: Colors.white,
            ),
            icon: Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.login, color: Colors.white, size: 20),
            ),
            label: const Text('Continuar con Google'),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF334455))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o inicia sesión con correo',
                style: TextStyle(color: Color(0xFF8899AA), fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFF334455))),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _passCtrl,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscure: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8899AA),
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D8B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿No tienes cuenta? ',
              style: TextStyle(color: Color(0xFF8899AA)),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/register'),
              child: const Text(
                'Regístrate',
                style: TextStyle(
                  color: Color(0xFFFF4D8B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMobileConnectPanel(BuildContext context) {
    return const _WebQRLoginPanel();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8899AA)),
        prefixIcon: Icon(icon, color: const Color(0xFF8899AA)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A2D42),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D8B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D8B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D8B), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF4D8B)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget de inicio de sesión QR estilo WhatsApp Web (solo en plataforma web)
// ─────────────────────────────────────────────────────────────────────────────

String _generateSessionId() => const Uuid().v4();

class _WebQRLoginPanel extends StatefulWidget {
  const _WebQRLoginPanel();

  @override
  State<_WebQRLoginPanel> createState() => _WebQRLoginPanelState();
}

class _WebQRLoginPanelState extends State<_WebQRLoginPanel> {
  final _service = QrSessionService();
  late final String _sessionId;
  StreamSubscription<WebSessionData>? _sub;
  bool _waiting = true; // esperando que el móvil apruebe
  bool _approved = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _sessionId = _generateSessionId();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      await _service.createWebSession(_sessionId);
      _sub = _service.watchSession(_sessionId).listen(_onSessionChange);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'Error al crear sesión: $e');
      }
    }
  }

  void _onSessionChange(WebSessionData data) {
    if (!mounted) return;
    if (data.status == WebSessionStatus.approved) {
      setState(() {
        _waiting = false;
        _approved = true;
      });
      _sub?.cancel();
      // Limpiar el nodo en RTDB
      _service.deleteSession(_sessionId);
      // Cargar el usuario en el AuthProvider
      final auth = context.read<AuthProvider>();
      auth.loginFromQRSession(
        uid: data.uid!,
        email: data.email!,
        username: data.username,
        firstName: data.firstName,
        lastName: data.lastName,
        avatarPath: data.avatarPath,
      );
      // Navegar al home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  Future<void> _refresh() async {
    _sub?.cancel();
    setState(() {
      _waiting = true;
      _approved = false;
      _errorMsg = null;
    });
    // Eliminar la sesión anterior si existe
    await _service.deleteSession(_sessionId);
    await _initSession();
    setState(() {}); // fuerza reconstrucción del QR
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String get _qrData =>
      '{"type":"airpulse_web_auth","sessionId":"$_sessionId"}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF4D8B).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smartphone, color: Color(0xFFFF4D8B), size: 32),
          const SizedBox(height: 12),
          const Text(
            'Iniciar sesión con el móvil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Abre AirPulse en tu teléfono y escanea el código.',
            style: TextStyle(color: Color(0xFF8899AA), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // ── QR o estado ──
          if (_errorMsg != null)
            _StatusBox(
              icon: Icons.error_outline,
              color: const Color(0xFFFF4D8B),
              label: _errorMsg!,
              actionLabel: 'Reintentar',
              onAction: _refresh,
            )
          else if (_approved)
            const _StatusBox(
              icon: Icons.check_circle_outline,
              color: Color(0xFF4CAF50),
              label: '¡Aprobado! Entrando…',
            )
          else
            GestureDetector(
              onTap: _waiting ? null : _refresh,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _waiting
                    ? QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 180,
                        foregroundColor: const Color(0xFF0D1B2A),
                        backgroundColor: Colors.white,
                      )
                    : const SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          if (!_approved && _errorMsg == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                const Text(
                  'Esperando aprobación…',
                  style: TextStyle(color: Color(0xFF8899AA), fontSize: 11),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _refresh,
                  child: const Text(
                    'Actualizar QR',
                    style: TextStyle(
                      color: Color(0xFFFF4D8B),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          // ── Instrucciones ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepItem(number: '1', text: 'Abre AirPulse en tu móvil'),
                SizedBox(height: 6),
                _StepItem(number: '2', text: 'Ve a Servidor → Escanear web'),
                SizedBox(height: 6),
                _StepItem(
                  number: '3',
                  text: 'Apunta la cámara al QR de arriba',
                ),
                SizedBox(height: 6),
                _StepItem(
                  number: '4',
                  text: '¡Sesión iniciada automáticamente!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusBox({
    required this.icon,
    required this.color,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: Color(0xFFFF4D8B), fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4D8B),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
