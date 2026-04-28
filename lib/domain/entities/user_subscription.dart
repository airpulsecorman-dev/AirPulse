import 'package:equatable/equatable.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';

/// Entidad que representa la suscripción activa del usuario
class UserSubscription extends Equatable {
  final String userId;
  final PlanType currentPlan;
  final DateTime subscribedDate;
  final DateTime? expiryDate;
  final bool isActive;
  final bool autoRenew;
  final PaymentMethod lastPaymentMethod;
  final String transactionId;

  const UserSubscription({
    required this.userId,
    required this.currentPlan,
    required this.subscribedDate,
    this.expiryDate,
    required this.isActive,
    required this.autoRenew,
    required this.lastPaymentMethod,
    required this.transactionId,
  });

  /// Crea una suscripción gratuita por defecto
  factory UserSubscription.free(String userId) {
    return UserSubscription(
      userId: userId,
      currentPlan: PlanType.free,
      subscribedDate: DateTime.now(),
      isActive: true,
      autoRenew: false,
      lastPaymentMethod: PaymentMethod.creditCard,
      transactionId: 'free_user',
    );
  }

  /// Copia la suscripción con nuevos valores
  UserSubscription copyWith({
    String? userId,
    PlanType? currentPlan,
    DateTime? subscribedDate,
    DateTime? expiryDate,
    bool? isActive,
    bool? autoRenew,
    PaymentMethod? lastPaymentMethod,
    String? transactionId,
  }) {
    return UserSubscription(
      userId: userId ?? this.userId,
      currentPlan: currentPlan ?? this.currentPlan,
      subscribedDate: subscribedDate ?? this.subscribedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        currentPlan,
        subscribedDate,
        expiryDate,
        isActive,
        autoRenew,
        lastPaymentMethod,
        transactionId,
      ];
}
