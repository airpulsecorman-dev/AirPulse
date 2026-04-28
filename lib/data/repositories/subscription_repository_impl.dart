import 'package:airpulse/data/models/subscription_model.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/domain/entities/user_subscription.dart';
import 'package:airpulse/domain/repositories/subscription_repository.dart';
import 'package:airpulse/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementación del repositorio de suscripción
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SharedPreferences prefs;
  final PaymentService paymentService;

  SubscriptionRepositoryImpl({
    required this.prefs,
    required this.paymentService,
  });

  /// Obtiene los planes disponibles
  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      // En una aplicación real, esto vendría de un API
      return SubscriptionPlan.getAllPlans();
    } catch (e) {
      throw Exception('Error al obtener planes: $e');
    }
  }

  /// Obtiene la suscripción actual del usuario
  @override
  Future<UserSubscription> getCurrentSubscription(String userId) async {
    try {
      final jsonString = prefs.getString('user_subscription_$userId');

      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Map.from(jsonString as Map),
        );
        return UserSubscriptionModel.fromJson(json);
      }

      // Si no existe, retorna plan gratuito
      return UserSubscription.free(userId);
    } catch (e) {
      // En caso de error, retorna plan gratuito
      return UserSubscription.free(userId);
    }
  }

  /// Mejora el plan del usuario
  @override
  Future<UserSubscription> upgradePlan(
    String userId,
    PlanType newPlan,
    PaymentMethod paymentMethod,
  ) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: 30)); // Suscripción mensual

      final updatedSubscription = UserSubscription(
        userId: userId,
        currentPlan: newPlan,
        subscribedDate: now,
        expiryDate: expiryDate,
        isActive: true,
        autoRenew: true,
        lastPaymentMethod: paymentMethod,
        transactionId: _generateTransactionId(),
      );

      // Guardar en SharedPreferences
      final model = UserSubscriptionModel(
        userId: updatedSubscription.userId,
        currentPlan: updatedSubscription.currentPlan,
        subscribedDate: updatedSubscription.subscribedDate,
        expiryDate: updatedSubscription.expiryDate,
        isActive: updatedSubscription.isActive,
        autoRenew: updatedSubscription.autoRenew,
        lastPaymentMethod: updatedSubscription.lastPaymentMethod,
        transactionId: updatedSubscription.transactionId,
      );

      final json = model.toJson();
      await prefs.setString('user_subscription_$userId', json.toString());

      return updatedSubscription;
    } catch (e) {
      throw Exception('Error al actualizar plan: $e');
    }
  }

  /// Cancela la suscripción del usuario
  @override
  Future<bool> cancelSubscription(String userId) async {
    try {
      await prefs.remove('user_subscription_$userId');
      return true;
    } catch (e) {
      throw Exception('Error al cancelar suscripción: $e');
    }
  }

  /// Verifica si una función está disponible para el plan actual
  @override
  Future<bool> isFeatureAvailable(String userId, String featureName) async {
    try {
      final subscription = await getCurrentSubscription(userId);
      final plan = SubscriptionPlan.getAllPlans()
          .firstWhere((p) => p.type == subscription.currentPlan);

      switch (featureName) {
        case 'offline_mode':
          return plan.supportsOfflineMode;
        case 'quality_selection':
          return plan.supportsQualitySelection;
        case 'playlist_sharing':
          return plan.supportsPlaylistSharing;
        case 'advanced_search':
          return plan.supportsAdvancedSearch;
        case 'remove_ads':
          return plan.removeAds;
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el historial de transacciones
  @override
  Future<List<SubscriptionTransaction>> getTransactionHistory(
      String userId) async {
    try {
      final transactions = <SubscriptionTransaction>[];

      // Aquí iría la lógica para obtener transacciones del usuario
      // Por ahora retorna una lista vacía
      return transactions;
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  /// Genera un ID de transacción único
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'txn_${timestamp}_${DateTime.now().microsecond}';
  }
}
