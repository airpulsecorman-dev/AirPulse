import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/domain/entities/user_subscription.dart';

/// Modelo de datos para la suscripción del usuario
class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.userId,
    required super.currentPlan,
    required super.subscribedDate,
    super.expiryDate,
    required super.isActive,
    required super.autoRenew,
    required super.lastPaymentMethod,
    required super.transactionId,
  });

  /// Crea desde JSON
  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      userId: json['userId'] ?? '',
      currentPlan: _parsePlanType(json['currentPlan']),
      subscribedDate: DateTime.parse(json['subscribedDate']),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? true,
      autoRenew: json['autoRenew'] ?? false,
      lastPaymentMethod: _parsePaymentMethod(json['lastPaymentMethod']),
      transactionId: json['transactionId'] ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentPlan': currentPlan.toString(),
      'subscribedDate': subscribedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'lastPaymentMethod': lastPaymentMethod.toString(),
      'transactionId': transactionId,
    };
  }

  static PlanType _parsePlanType(String? value) {
    if (value == null) return PlanType.free;
    return PlanType.values.firstWhere(
      (plan) => plan.toString() == value,
      orElse: () => PlanType.free,
    );
  }

  static PaymentMethod _parsePaymentMethod(String? value) {
    if (value == null) return PaymentMethod.creditCard;
    return PaymentMethod.values.firstWhere(
      (method) => method.toString() == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }
}

/// Modelo de datos para las transacciones
class SubscriptionTransactionModel {
  final String transactionId;
  final String userId;
  final PlanType planType;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final DateTime transactionDate;
  final String status;

  SubscriptionTransactionModel({
    required this.transactionId,
    required this.userId,
    required this.planType,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionDate,
    required this.status,
  });

  /// Crea desde JSON
  factory SubscriptionTransactionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransactionModel(
      transactionId: json['transactionId'] ?? '',
      userId: json['userId'] ?? '',
      planType: _parsePlanType(json['planType']),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '\$',
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      transactionDate: DateTime.parse(json['transactionDate']),
      status: json['status'] ?? 'pending',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'planType': planType.toString(),
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.toString(),
      'transactionDate': transactionDate.toIso8601String(),
      'status': status,
    };
  }

  static PlanType _parsePlanType(String? value) {
    if (value == null) return PlanType.free;
    return PlanType.values.firstWhere(
      (plan) => plan.toString() == value,
      orElse: () => PlanType.free,
    );
  }

  static PaymentMethod _parsePaymentMethod(String? value) {
    if (value == null) return PaymentMethod.creditCard;
    return PaymentMethod.values.firstWhere(
      (method) => method.toString() == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }
}
