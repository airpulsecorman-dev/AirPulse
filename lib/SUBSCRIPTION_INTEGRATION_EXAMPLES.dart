// Ejemplo de integración del sistema de suscripción en AirPulse

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/presentation/hooks/use_subscription.dart';
import 'package:airpulse/presentation/pages/pricing_page.dart';
import 'package:airpulse/presentation/components/feature_guard.dart';
import 'package:airpulse/presentation/components/payment_form_dialog.dart';
import 'package:airpulse/services/payment_service.dart';

// ============================================================================
// EJEMPLO 1: Acceder a la página de planes
// ============================================================================

class MenuExample extends StatelessWidget {
  final String userId;

  const MenuExample({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PricingPage(userId: userId)),
        );
      },
      child: const Text('Ver Planes de Suscripción'),
    );
  }
}

// ============================================================================
// EJEMPLO 2: Usar el hook de suscripción
// ============================================================================

class SubscriptionStatusWidget extends HookWidget {
  final String userId;

  const SubscriptionStatusWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    return Column(
      children: [
        if (subscription.isLoading)
          const CircularProgressIndicator()
        else ...[
          Text(
            'Plan Actual: ${subscription.currentPlan?.name ?? "Cargando..."}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PricingPage(userId: userId),
                ),
              );
            },
            child: const Text('Actualizar Plan'),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// EJEMPLO 3: Bloquear una característica con FeatureGuard
// ============================================================================

class OfflineModeExample extends StatelessWidget {
  final String userId;

  const OfflineModeExample({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FeatureGuard(
      userId: userId,
      featureName: 'offline_mode',
      featureDisplayName: 'Descargas y Modo Sin Conexión',
      requiredPlan: SubscriptionPlan.starter(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(Icons.download_done, color: Colors.green),
            const SizedBox(height: 8),
            const Text(
              'Descargar Canción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Descargando canción...')),
                );
              },
              child: const Text('Descargar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 4: Verificar características dinámicamente
// ============================================================================

class QualitySelectionExample extends HookWidget {
  final String userId;

  const QualitySelectionExample({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    if (subscription.isLoading) {
      return const CircularProgressIndicator();
    }

    // Verificar si la característica está disponible
    final hasQualitySelection =
        subscription.currentPlan?.supportsQualitySelection ?? false;

    return Column(
      children: [
        Text(
          'Selección de Calidad',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (hasQualitySelection) ...[
          DropdownButton<String>(
            value: '320 kbps',
            items: const [
              DropdownMenuItem(value: '128 kbps', child: Text('128 kbps')),
              DropdownMenuItem(value: '256 kbps', child: Text('256 kbps')),
              DropdownMenuItem(value: '320 kbps', child: Text('320 kbps')),
              DropdownMenuItem(value: 'lossless', child: Text('Sin Pérdida')),
            ],
            onChanged: (value) {},
          ),
        ] else ...[
          const Text('Disponible en planes Pro y superiores'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PricingPage(userId: userId),
                ),
              );
            },
            child: const Text('Actualizar Plan'),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// EJEMPLO 5: Mostrar diálogo de pago personalizado
// ============================================================================

class CustomPaymentExample extends StatelessWidget {
  final String userId;
  final PaymentService paymentService;

  const CustomPaymentExample({
    super.key,
    required this.userId,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    final plan = SubscriptionPlan.pro();

    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => PaymentFormDialog(
            plan: plan,
            paymentService: paymentService,
            onPaymentComplete: (success, transactionId) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago exitoso. ID: $transactionId'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error en el pago'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
      child: const Text('Pagar'),
    );
  }
}

// ============================================================================
// EJEMPLO 6: Botón "Actualizar Plan" en la barra del reproductor
// ============================================================================

class PlayerBarUpgradeButton extends HookWidget {
  final String userId;

  const PlayerBarUpgradeButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    // Solo mostrar si está en plan gratuito
    if (subscription.currentPlan?.type == PlanType.free) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
          label: const Text('Actualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================================
// EJEMPLO 7: Integración en un widget existente
// ============================================================================

class LibraryPageWithUpgrade extends HookWidget {
  final String userId;

  const LibraryPageWithUpgrade({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          if (subscription.currentPlan?.type == PlanType.free)
            Padding(
              padding: const EdgeInsets.all(8),
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
                label: const Text('Actualizar'),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // Contenido de la biblioteca aquí
          FeatureGuard(
            userId: userId,
            featureName: 'playlist_sharing',
            featureDisplayName: 'Compartir Playlists',
            child: ListTile(
              title: const Text('Compartir Playlist'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compartiendo...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 8: Hook personalizado para verificar característica
// ============================================================================

bool useIsFeatureAvailable(String userId, String featureName) {
  final subscription = useSubscription(userId);

  if (subscription.currentPlan == null) {
    return false;
  }

  switch (featureName) {
    case 'offline_mode':
      return subscription.currentPlan!.supportsOfflineMode;
    case 'quality_selection':
      return subscription.currentPlan!.supportsQualitySelection;
    case 'playlist_sharing':
      return subscription.currentPlan!.supportsPlaylistSharing;
    case 'advanced_search':
      return subscription.currentPlan!.supportsAdvancedSearch;
    case 'remove_ads':
      return subscription.currentPlan!.removeAds;
    default:
      return true;
  }
}

// Uso:
class FeatureAvailabilityExample extends HookWidget {
  final String userId;

  const FeatureAvailabilityExample({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final hasOfflineMode = useIsFeatureAvailable(userId, 'offline_mode');

    return Container(
      color: hasOfflineMode ? Colors.green[100] : Colors.red[100],
      child: Text(
        hasOfflineMode
            ? 'Modo sin conexión disponible'
            : 'Modo sin conexión no disponible',
      ),
    );
  }
}
