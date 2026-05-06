import 'package:flutter/material.dart';
import 'intellectual_property_page.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _audioQuality = 'alta';

  @override
  Widget build(BuildContext context) {
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
                  subtitle: Text(_audioQuality),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showQualityDialog(),
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
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
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
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                  },
                ),
              ],
            ),

            // Almacenamiento
            _SettingsSection(
              title: 'Almacenamiento',
              children: [
                ListTile(
                  title: const Text('Limpiar caché'),
                  subtitle: const Text('Liberar espacio'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearCacheDialog(),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Propiedad Intelectual'),
                  subtitle: const Text('Política de propiedad intelectual'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IntellectualPropertyPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Política de Privacidad'),
                  subtitle: const Text('Cómo gestionamos tus datos personales'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Calidad de audio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Baja (96 kbps)'),
              value: 'baja',
              groupValue: _audioQuality,
              onChanged: (value) {
                setState(() => _audioQuality = value ?? 'baja');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Media (192 kbps)'),
              value: 'media',
              groupValue: _audioQuality,
              onChanged: (value) {
                setState(() => _audioQuality = value ?? 'media');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Alta (320 kbps)'),
              value: 'alta',
              groupValue: _audioQuality,
              onChanged: (value) {
                setState(() => _audioQuality = value ?? 'alta');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiado correctamente')),
              );
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
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
