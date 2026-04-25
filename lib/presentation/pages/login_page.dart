import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import 'web_library_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _serverUrlCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _serverUrlCtrl.dispose();
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
    // QR que contiene la URL actual de la web app para que el móvil la identifique
    final webUrl = Uri.base.toString();
    final qrData = webUrl;

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
            'Reproducir desde el móvil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Escucha tu música del móvil directamente desde el navegador.',
            style: TextStyle(color: Color(0xFF8899AA), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // QR de la web app
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160,
              foregroundColor: const Color(0xFF0D1B2A),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '← Escanea desde el móvil para abrir esta URL',
            style: TextStyle(color: Color(0xFF8899AA), fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: Color(0xFF334455))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o conecta manualmente',
                    style: TextStyle(color: Color(0xFF8899AA), fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFF334455))),
              ],
            ),
          ),
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepItem(number: '1', text: 'Abre AirPulse en tu móvil'),
                SizedBox(height: 6),
                _StepItem(
                  number: '2',
                  text: 'Ve a Servidor → Iniciar servidor',
                ),
                SizedBox(height: 6),
                _StepItem(
                  number: '3',
                  text: 'Copia la URL que aparece en tu móvil',
                ),
                SizedBox(height: 6),
                _StepItem(number: '4', text: 'Pégala abajo y toca Conectar'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serverUrlCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'http://192.168.x.x:8765',
              hintStyle: const TextStyle(
                color: Color(0xFF8899AA),
                fontSize: 13,
              ),
              labelText: 'URL del servidor móvil',
              labelStyle: const TextStyle(color: Color(0xFF8899AA)),
              prefixIcon: const Icon(Icons.link, color: Color(0xFF8899AA)),
              filled: true,
              fillColor: const Color(0xFF0D1B2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF4D8B),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                final url = _serverUrlCtrl.text.trim();
                if (url.isEmpty) return;
                final normalized = url.endsWith('/')
                    ? url.substring(0, url.length - 1)
                    : url;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebLibraryPage(serverUrl: normalized),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D8B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.wifi_tethering, size: 18),
              label: const Text(
                'Conectar con móvil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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
