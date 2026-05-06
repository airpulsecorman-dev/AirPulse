import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'google_onboarding_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'intellectual_property_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  DateTime? _birthDate;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedIntellectual = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _cedulaCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get _isMinor {
    if (_birthDate == null) return false;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age < 18;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF4D8B),
            onPrimary: Colors.white,
            surface: Color(0xFF1A2D42),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      _showError('Selecciona tu fecha de nacimiento.');
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy || !_acceptedIntellectual) {
      _showError(
          'Debes aceptar los términos, la política de privacidad y la propiedad intelectual.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _usernameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      cedula: _cedulaCtrl.text.trim(),
      birthDate: _birthDate!,
      acceptedTerms: _acceptedTerms,
      acceptedPrivacy: _acceptedPrivacy,
      acceptedIntellectual: _acceptedIntellectual,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      _showError(auth.errorMessage ?? 'Error al registrarse');
    }
  }

  Future<void> _googleRegister() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      final user = auth.currentUser;
      if (user != null && !user.acceptedTerms) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const GoogleOnboardingPage()),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else {
      _showError(auth.errorMessage ?? 'Error con Google');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF4D8B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 64 : 28,
                  vertical: 24,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBranding()),
                          const SizedBox(width: 48),
                          Expanded(child: _buildForm(auth)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildBranding(),
                          const SizedBox(height: 28),
                          _buildForm(auth),
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
        const SizedBox(height: 20),
        const Text(
          'AirPulse',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crear cuenta',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Únete a AirPulse',
          style: TextStyle(color: Color(0xFF8899AA), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Column(
      children: [
        // ── Google ────────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading ? null : _googleRegister,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF334455)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
              child: Text('o regístrate con correo',
                  style:
                      TextStyle(color: Color(0xFF8899AA), fontSize: 12)),
            ),
            Expanded(child: Divider(color: Color(0xFF334455))),
          ],
        ),
        const SizedBox(height: 20),
        // ── Form ─────────────────────────────────────────────────────────────
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre / Apellido
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _firstNameCtrl,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _lastNameCtrl,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _usernameCtrl,
                label: 'Nombre de usuario',
                icon: Icons.alternate_email,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa un nombre de usuario';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              _buildField(
                controller: _cedulaCtrl,
                label: 'Cédula / Documento de identidad',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu cédula';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Fecha de nacimiento
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2D42),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined,
                          color: Color(0xFF8899AA)),
                      const SizedBox(width: 12),
                      Text(
                        _birthDate == null
                            ? 'Fecha de nacimiento'
                            : '${_birthDate!.day.toString().padLeft(2, '0')} / ${_birthDate!.month.toString().padLeft(2, '0')} / ${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null
                              ? const Color(0xFF8899AA)
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_birthDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        _isMinor ? Icons.child_care : Icons.verified_user,
                        size: 16,
                        color: _isMinor ? Colors.amber : Colors.greenAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isMinor
                              ? 'Menor de edad — Suscripción Gratis (sin cambio hasta los 18 años)'
                              : 'Mayor de edad — puedes elegir tu plan',
                          style: TextStyle(
                            color: _isMinor
                                ? Colors.amber
                                : Colors.greenAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
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
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmPassCtrl,
                label: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8899AA),
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // ── Aceptaciones legales ─────────────────────────────────────
              _buildCheckRow(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v!),
                label: 'Acepto los ',
                linkLabel: 'Términos y Condiciones',
                onLinkTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsPage()),
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckRow(
                value: _acceptedPrivacy,
                onChanged: (v) => setState(() => _acceptedPrivacy = v!),
                label: 'Acepto la ',
                linkLabel: 'Política de Privacidad',
                onLinkTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage()),
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckRow(
                value: _acceptedIntellectual,
                onChanged: (v) =>
                    setState(() => _acceptedIntellectual = v!),
                label: 'Acepto la ',
                linkLabel: 'Política de Propiedad Intelectual',
                onLinkTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IntellectualPropertyPage()),
                ),
              ),
              const SizedBox(height: 28),
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
                          'Crear cuenta',
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
              '¿Ya tienes cuenta? ',
              style: TextStyle(color: Color(0xFF8899AA)),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: Color(0xFFFF4D8B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCheckRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String linkLabel,
    required VoidCallback onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF4D8B),
            side: const BorderSide(color: Color(0xFF8899AA)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              style:
                  const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
              children: [
                TextSpan(
                  text: linkLabel,
                  style: const TextStyle(
                    color: Color(0xFFFF4D8B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                ),
              ],
            ),
          ),
        ),
      ],
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
          borderSide:
              const BorderSide(color: Color(0xFFFF4D8B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF4D8B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF4D8B), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF4D8B)),
      ),
    );
  }
}
