import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

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
          opacity: _animationController,
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

                    // Suscripción
                    _SubscriptionCard(user: user),
                    const SizedBox(height: 24),

                    // Métodos de pago
                    _PaymentMethodsCard(user: user),
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
    return username.isNotEmpty
        ? username.substring(0, 1).toUpperCase()
        : '?';
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
                  color: Colors.black.withValues(alpha: 0.2),
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

// Tarjeta de suscripción
class _SubscriptionCard extends StatelessWidget {
  final dynamic user;

  const _SubscriptionCard({required this.user});

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
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Suscripción',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Plan Gratuito',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.info,
                    color: theme.colorScheme.onSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualiza a Premium para acceder a todas las funciones exclusivas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navegar a suscripciones
                },
                child: const Text('Actualizar Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de métodos de pago
class _PaymentMethodsCard extends StatelessWidget {
  final dynamic user;

  const _PaymentMethodsCard({required this.user});

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
                    Icon(
                      Icons.payment,
                      color: theme.colorScheme.primary,
                    ),
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
                    // Agregar método de pago
                  },
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              cardType: 'Visa',
              lastDigits: '4242',
              expiryDate: '12/25',
              isDefault: true,
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              cardType: 'Mastercard',
              lastDigits: '5555',
              expiryDate: '08/26',
              isDefault: false,
            ),
          ],
        ),
      ),
    );
  }
}

// Elemento de método de pago
class _PaymentMethodItem extends StatelessWidget {
  final String cardType;
  final String lastDigits;
  final String expiryDate;
  final bool isDefault;

  const _PaymentMethodItem({
    required this.cardType,
    required this.lastDigits,
    required this.expiryDate,
    required this.isDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDefault
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isDefault
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    cardType == 'Visa' ? Icons.credit_card : Icons.credit_card,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$cardType • $lastDigits',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Expira: $expiryDate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Por defecto',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              PopupMenuButton(
                itemBuilder: (context) => [
                  if (!isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Establecer como predeterminada'),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
                ],
                onSelected: (value) {
                  // Manejar acciones
                },
              ),
            ],
          ),
        ],
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
            Navigator.pushNamed(context, '/change-password');
          },
        ),
        _SettingsTile(
          icon: Icons.notifications,
          title: 'Notificaciones',
          onTap: () {
            // Navegar a notificaciones
          },
        ),
        _SettingsTile(
          icon: Icons.privacy_tip,
          title: 'Privacidad',
          onTap: () {
            // Navegar a privacidad
          },
        ),
        _SettingsTile(
          icon: Icons.help,
          title: 'Ayuda y Soporte',
          onTap: () {
            // Abrir ayuda
          },
        ),
      ],
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
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
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
              Navigator.pushNamed(context, '/edit-profile');
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
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
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

  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
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
