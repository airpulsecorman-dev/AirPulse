import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'intellectual_property_page.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';
import '../../core/utils/Colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Audio
            _SettingsSection(
              title: 'Audio',
              children: [
                ListTile(
                  title: const Text('Calidad de audio'),
                  subtitle: Text(_qualityLabel(settings.audioQuality)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showQualityDialog(context, settings),
                ),
              ],
            ),

            // Notificaciones
            _SettingsSection(
              title: 'Notificaciones',
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones habilitadas'),
                  subtitle: const Text('Recibir actualizaciones'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotifications(value),
                ),
              ],
            ),

            // Apariencia
            _SettingsSection(
              title: 'Apariencia',
              children: [
                SwitchListTile(
                  title: const Text('Modo oscuro'),
                  subtitle: const Text('Usar tema oscuro'),
                  value: settings.darkModeEnabled,
                  onChanged: (value) => settings.setDarkMode(value),
                ),
              ],
            ),

            // Almacenamiento
            _SettingsSection(
              title: 'Almacenamiento',
              children: [
                ListTile(
                  title: const Text('Limpiar caché'),
                  subtitle: const Text('Liberar espacio en el dispositivo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearCacheDialog(context, settings),
                ),
              ],
            ),

            // Información
            _SettingsSection(
              title: 'Información',
              children: [
                ListTile(
                  title: const Text('Versión de la app'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Desarrollador'),
                  subtitle: const Text('AirPulse Dev Team'),
                ),
                ListTile(
                  title: const Text('Términos y Condiciones'),
                  subtitle: const Text('Leer los términos de uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsPage()),
                  ),
                ),
                ListTile(
                  title: const Text('Propiedad Intelectual'),
                  subtitle: const Text('Política de propiedad intelectual'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IntellectualPropertyPage(),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Política de Privacidad'),
                  subtitle: const Text('Cómo gestionamos tus datos personales'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(String quality) {
    switch (quality) {
      case 'baja':
        return 'Baja (96 kbps)';
      case 'media':
        return 'Media (192 kbps)';
      default:
        return 'Alta (320 kbps)';
    }
  }

  void _showQualityDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Calidad de audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['baja', 'media', 'alta'].map((q) {
              return RadioListTile<String>(
                title: Text(_qualityLabel(q)),
                value: q,
                groupValue: settings.audioQuality,
                onChanged: (value) {
                  if (value != null) {
                    settings.setAudioQuality(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text(
          '¿Estás seguro de que deseas limpiar el caché? Esto liberará espacio en tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final mb = await settings.clearCache();
              if (context.mounted) {
                final label = mb > 0
                    ? 'Caché limpiado (${mb.toStringAsFixed(1)} MB liberados)'
                    : 'Caché limpiado correctamente';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(label)));
              }
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
