import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'intellectual_property_page.dart';
import '../../core/utils/Colors.dart';

class GoogleOnboardingPage extends StatefulWidget {
  const GoogleOnboardingPage({super.key});

  @override
  State<GoogleOnboardingPage> createState() => _GoogleOnboardingPageState();
}

class _GoogleOnboardingPageState extends State<GoogleOnboardingPage> {
  DateTime? _birthDate;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedIntellectual = false;

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
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.surface,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _submit() async {
    if (_birthDate == null) {
      _showError('Selecciona tu fecha de nacimiento.');
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy || !_acceptedIntellectual) {
      _showError(
        'Debes aceptar los términos, la política de privacidad y la propiedad intelectual.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.completeGoogleOnboarding(
      birthDate: _birthDate!,
      acceptedTerms: _acceptedTerms,
      acceptedPrivacy: _acceptedPrivacy,
      acceptedIntellectual: _acceptedIntellectual,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      _showError(auth.errorMessage ?? 'Error al guardar los datos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'AirPulse',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (user != null) ...[
                          Text(
                            'Bienvenido, ${user.firstName.isNotEmpty ? user.firstName : user.username}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          'Para continuar, completa los siguientes datos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Fecha de nacimiento
                  const Text(
                    'Fecha de nacimiento',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_outlined,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _birthDate == null
                                ? 'Seleccionar fecha'
                                : '${_birthDate!.day.toString().padLeft(2, '0')} / ${_birthDate!.month.toString().padLeft(2, '0')} / ${_birthDate!.year}',
                            style: TextStyle(
                              color: _birthDate == null
                                  ? AppColors.textTertiary
                                  : AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_birthDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isMinor ? Icons.child_care : Icons.verified_user,
                          size: 16,
                          color: _isMinor
                              ? AppColors.warningAmber
                              : AppColors.successAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isMinor
                                ? 'Menor de edad — Suscripción Gratis (sin cambio hasta los 18 años)'
                                : 'Mayor de edad — puedes elegir tu plan',
                            style: TextStyle(
                              color: _isMinor
                                  ? AppColors.warningAmber
                                  : AppColors.successAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Aceptaciones legales
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
                  const SizedBox(height: 10),
                  _buildCheckRow(
                    value: _acceptedPrivacy,
                    onChanged: (v) => setState(() => _acceptedPrivacy = v!),
                    label: 'Acepto la ',
                    linkLabel: 'Política de Privacidad',
                    onLinkTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckRow(
                    value: _acceptedIntellectual,
                    onChanged: (v) =>
                        setState(() => _acceptedIntellectual = v!),
                    label: 'Acepto la ',
                    linkLabel: 'Política de Propiedad Intelectual',
                    onLinkTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IntellectualPropertyPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón continuar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
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
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cerrar sesión
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text(
                        'Cancelar y cerrar sesión',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: linkLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
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
}
