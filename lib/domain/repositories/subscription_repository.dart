import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/domain/entities/user_subscription.dart';

abstract class SubscriptionRepository {
  /// Obtiene los planes disponibles
  Future<List<SubscriptionPlan>> getAvailablePlans();

  /// Obtiene la suscripción actual del usuario
  Future<UserSubscription> getCurrentSubscription(String userId);

  /// Actualiza el plan del usuario
  Future<UserSubscription> upgradePlan(
    String userId,
    PlanType newPlan,
    PaymentMethod paymentMethod,
  );

  /// Cancela la suscripción del usuario
  Future<bool> cancelSubscription(String userId);

  /// Verifica si una función está disponible para el plan actual
  Future<bool> isFeatureAvailable(String userId, String featureName);

  /// Obtiene el historial de transacciones
  Future<List<SubscriptionTransaction>> getTransactionHistory(String userId);
}

/// Modelo para transacciones
class SubscriptionTransaction {
  final String transactionId;
  final String userId;
  final PlanType planType;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final DateTime transactionDate;
  final String status; // 'completed', 'pending', 'failed'

  SubscriptionTransaction({
    required this.transactionId,
    required this.userId,
    required this.planType,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionDate,
    required this.status,
  });
}
