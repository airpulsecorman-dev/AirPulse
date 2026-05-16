import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../core/utils/Colors.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/presentation/hooks/use_subscription.dart';
import 'package:airpulse/presentation/pages/pricing_page.dart';

/// Widget que bloquea características según el plan del usuario
class FeatureGuard extends HookWidget {
  final String userId;
  final String featureName;
  final String featureDisplayName;
  final SubscriptionPlan? requiredPlan;
  final Widget child;

  const FeatureGuard({
    super.key,
    required this.userId,
    required this.featureName,
    required this.featureDisplayName,
    this.requiredPlan,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    if (subscription.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isFeatureAvailable = _checkFeatureAvailability(
      subscription.currentPlan,
    );

    if (isFeatureAvailable) {
      return child;
    }

    // Mostrar overlay de bloqueo
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: child),
        Center(
          child: GestureDetector(
            onTap: () {
              _showUpgradeDialog(context, subscription);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPricing,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warningAmber, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.lock, color: AppColors.warningAmber, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Característica Bloqueada',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        featureDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Actualiza tu plan para acceder',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _checkFeatureAvailability(SubscriptionPlan? currentPlan) {
    if (currentPlan == null) return false;

    switch (featureName) {
      case 'offline_mode':
        return currentPlan.supportsOfflineMode;
      case 'quality_selection':
        return currentPlan.supportsQualitySelection;
      case 'playlist_sharing':
        return currentPlan.supportsPlaylistSharing;
      case 'advanced_search':
        return currentPlan.supportsAdvancedSearch;
      case 'remove_ads':
        return currentPlan.removeAds;
      default:
        return true;
    }
  }

  void _showUpgradeDialog(
    BuildContext context,
    SubscriptionHookState subscription,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundPricing,
        title: Text(
          featureDisplayName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.white),
        ),
        content: Text(
          'Esta característica requiere un plan de pago.\n\nToca "Ver Planes" para actualizar tu suscripción.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.grey300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PricingPage(userId: userId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningAmber,
            ),
            child: const Text(
              'Ver Planes',
              style: TextStyle(color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente simplificado para bloqueadores de características
class FeatureBlocker extends StatelessWidget {
  final String featureDisplayName;
  final VoidCallback onUpgrade;
  final bool isBlocked;
  final Widget child;

  const FeatureBlocker({
    super.key,
    required this.featureDisplayName,
    required this.onUpgrade,
    required this.isBlocked,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlocked) {
      return child;
    }

    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Opacity(opacity: 0.5, child: child),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    color: AppColors.warningAmber,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan Requerido',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
