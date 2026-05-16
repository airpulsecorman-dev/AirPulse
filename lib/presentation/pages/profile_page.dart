import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../hooks/use_subscription.dart';
import './pricing_page.dart';
import './change_password_page.dart';
import './edit_profile_page.dart';
import './terms_page.dart';
import './privacy_policy_page.dart';
import './intellectual_property_page.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../core/utils/Colors.dart';

class ProfilePage extends HookWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, [animationController]);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil'), centerTitle: true),
        body: Center(
          child: Text(
            'No hay usuario autenticado',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: animationController,
          child: Column(
            children: [
              // Header con avatar y nombre
              _HeaderProfile(user: user, theme: theme),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Información del usuario
                    _UserInfoCard(user: user),
                    const SizedBox(height: 24),

                    // Suscripción - Integrada con el hook
                    _SubscriptionCard(userId: user.id),
                    const SizedBox(height: 24),

                    // Métodos de pago - Integrada
                    _PaymentMethodsCard(userId: user.id),
                    const SizedBox(height: 24),

                    // Opciones y preferencias
                    _SettingsSection(),
                    const SizedBox(height: 24),

                    // Botones de acción
                    _ActionButtons(user: user, auth: auth),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget del header con avatar
class _HeaderProfile extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;

  const _HeaderProfile({required this.user, required this.theme});

  String _getInitials() {
    final username = user?.username ?? '';
    return username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.username ?? 'Usuario',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'email@example.com',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta de información del usuario
class _UserInfoCard extends StatelessWidget {
  final dynamic user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Usuario',
              value: user?.username ?? '—',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Email',
              value: user?.email ?? '—',
              icon: Icons.email,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Miembro desde',
              value: user?.createdAt != null
                  ? user!.createdAt.toString().split(' ')[0]
                  : '—',
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de suscripción - INTEGRADA CON HOOK
class _SubscriptionCard extends HookWidget {
  final String userId;

  const _SubscriptionCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = useSubscription(userId);

    if (subscription.isLoading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
        ),
      );
    }

    final currentPlan = subscription.currentPlan;
    final isFreePlan = currentPlan?.type == PlanType.free;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Suscripción Actual',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mostrar plan actual
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlan?.name ?? 'Cargando...',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentPlan?.price == 0
                            ? 'Gratuito'
                            : '\$${currentPlan?.price.toStringAsFixed(2)}/mes',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondary.withValues(
                            alpha: 0.9,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isFreePlan ? Icons.lock_outline : Icons.verified,
                    color: theme.colorScheme.onSecondary,
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Características del plan
            if (currentPlan != null) ...[
              Text(
                'Características:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ...currentPlan.features.take(3).map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (currentPlan.features.length > 3)
                Text(
                  '+ ${currentPlan.features.length - 3} más',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            // Descripción
            Text(
              isFreePlan
                  ? 'Actualiza a un plan premium para acceder a todas las funciones exclusivas'
                  : currentPlan?.description ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Botón de acción
            if (isFreePlan)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PricingPage(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Actualizar Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PricingPage(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.change_circle),
                  label: const Text('Cambiar Plan'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de métodos de pago - INTEGRADA
class _PaymentMethodsCard extends HookWidget {
  final String userId;

  const _PaymentMethodsCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Métodos de Pago',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agregar nuevo método de pago'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Métodos disponibles
            _PaymentMethodItem(
              method: PaymentMethod.creditCard,
              title: 'Tarjeta de Crédito',
              icon: Icons.credit_card,
              isDefault: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarjeta de crédito seleccionada'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              method: PaymentMethod.paypal,
              title: 'PayPal',
              icon: Icons.payment,
              isDefault: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PayPal seleccionado'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              method: PaymentMethod.debitCard,
              title: 'Tarjeta de Débito',
              icon: Icons.credit_card,
              isDefault: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarjeta de débito seleccionada'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Elemento de método de pago
class _PaymentMethodItem extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final IconData icon;
  final bool isDefault;
  final VoidCallback onTap;

  const _PaymentMethodItem({
    required this.method,
    required this.title,
    required this.icon,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDefault
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isDefault ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDefault
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDefault
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                  color: isDefault
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Predeterminado',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// Sección de configuración
class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferencias',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.lock,
          title: 'Cambiar Contraseña',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.notifications,
          title: 'Notificaciones',
          onTap: () => _showNotificationsDialog(context),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip,
          title: 'Política de Privacidad',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.description,
          title: 'Términos y Condiciones',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsPage()),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.gavel,
          title: 'Propiedad Intelectual',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IntellectualPropertyPage(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.help,
          title: 'Ayuda y Soporte',
          onTap: () => _showSupportDialog(context),
        ),
      ],
    );
  }
}

void _showCopyEmailDialog(BuildContext context, String email) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sin app de correo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No encontramos una app de correo en tu dispositivo. Puedes escribirnos directamente a:',
          ),
          const SizedBox(height: 16),
          SelectableText(
            email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copiar'),
          onPressed: () {
            // ignore: deprecated_member_use
            Clipboard.setData(ClipboardData(text: email));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email copiado al portapapeles')),
            );
          },
        ),
      ],
    ),
  );
}

void _showSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline),
          SizedBox(width: 8),
          Text('Ayuda y Soporte'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿En qué podemos ayudarte?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SupportOption(
            icon: Icons.email_outlined,
            title: 'Contactar soporte',
            subtitle: 'Envíanos un correo y te respondemos pronto',
            onTap: () async {
              Navigator.pop(context);
              final uri = Uri(
                scheme: 'mailto',
                path: 'airpulsecorman@gmail.com',
                queryParameters: {
                  'subject': 'Soporte AirPulse',
                  'body': 'Hola, necesito ayuda con...',
                },
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                _showCopyEmailDialog(context, 'airpulsecorman@gmail.com');
              }
            },
          ),
          const SizedBox(height: 8),
          _SupportOption(
            icon: Icons.bug_report_outlined,
            title: 'Reportar un problema',
            subtitle: 'Cuéntanos si algo no funciona bien',
            onTap: () async {
              Navigator.pop(context);
              final uri = Uri(
                scheme: 'mailto',
                path: 'airpulsecorman@gmail.com',
                queryParameters: {
                  'subject': 'Reporte de problema – AirPulse',
                  'body':
                      'Describe el problema que encontraste:\n\n'
                      'Dispositivo: \nVersión de la app: 1.0.0\n\nDescripción:\n',
                },
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                _showCopyEmailDialog(context, 'airpulsecorman@gmail.com');
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showNotificationsDialog(BuildContext context) async {
  final status = await Permission.notification.status;
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Notificaciones'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AirPulse usa notificaciones para:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _NotifBullet(
            icon: Icons.music_note,
            text: 'Mostrar controles de reproducción en la pantalla de bloqueo',
          ),
          const _NotifBullet(
            icon: Icons.bluetooth,
            text:
                'Controlar la música desde auriculares y dispositivos Bluetooth',
          ),
          const _NotifBullet(
            icon: Icons.headphones,
            text: 'Reproducir música en segundo plano sin interrupciones',
          ),
          const SizedBox(height: 16),
          Text(
            status.isGranted
                ? '✅ Las notificaciones están habilitadas.'
                : '⚠️ Las notificaciones están deshabilitadas. Actívalas desde los ajustes del sistema para disfrutar de la reproducción en segundo plano.',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (!status.isGranted)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
      ],
    ),
  );
}

class _NotifBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NotifBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// Elemento de configuración
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Botones de acción
class _ActionButtons extends StatelessWidget {
  final dynamic user;
  final AuthProvider auth;

  const _ActionButtons({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar Perfil'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context, auth);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

// Fila de información reutilizable
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
