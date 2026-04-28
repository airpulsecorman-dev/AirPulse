import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/domain/entities/user_subscription.dart';
import 'package:airpulse/domain/repositories/subscription_repository.dart';

/// Obtiene los planes disponibles
class GetAvailablePlansUseCase {
  final SubscriptionRepository repository;

  GetAvailablePlansUseCase(this.repository);

  Future<List<SubscriptionPlan>> call() {
    return repository.getAvailablePlans();
  }
}

/// Obtiene la suscripción actual del usuario
class GetCurrentSubscriptionUseCase {
  final SubscriptionRepository repository;

  GetCurrentSubscriptionUseCase(this.repository);

  Future<UserSubscription> call(String userId) {
    return repository.getCurrentSubscription(userId);
  }
}

/// Mejora el plan del usuario
class UpgradePlanUseCase {
  final SubscriptionRepository repository;

  UpgradePlanUseCase(this.repository);

  Future<UserSubscription> call(
    String userId,
    PlanType newPlan,
    PaymentMethod paymentMethod,
  ) {
    return repository.upgradePlan(userId, newPlan, paymentMethod);
  }
}

/// Cancela la suscripción del usuario
class CancelSubscriptionUseCase {
  final SubscriptionRepository repository;

  CancelSubscriptionUseCase(this.repository);

  Future<bool> call(String userId) {
    return repository.cancelSubscription(userId);
  }
}

/// Verifica si una función está disponible
class IsFeatureAvailableUseCase {
  final SubscriptionRepository repository;

  IsFeatureAvailableUseCase(this.repository);

  Future<bool> call(String userId, String featureName) {
    return repository.isFeatureAvailable(userId, featureName);
  }
}

/// Obtiene el historial de transacciones
class GetTransactionHistoryUseCase {
  final SubscriptionRepository repository;

  GetTransactionHistoryUseCase(this.repository);

  Future<List<SubscriptionTransaction>> call(String userId) {
    return repository.getTransactionHistory(userId);
  }
}
