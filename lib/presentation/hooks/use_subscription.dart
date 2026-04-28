import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:airpulse/core/di/service_locator.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/domain/usecases/subscription_usecases.dart';

/// Hook personalizado para manejar suscripciones
SubscriptionHookState useSubscription(String userId) {
  return use(_SubscriptionHook(userId));
}

class SubscriptionHookState {
  final bool isLoading;
  final List<SubscriptionPlan> plans;
  final SubscriptionPlan? currentPlan;
  final Future<void> Function() refreshPlans;
  final Future<bool> Function(PlanType, PaymentMethod) upgradePlan;
  final Future<void> Function() cancelSubscription;

  SubscriptionHookState({
    required this.isLoading,
    required this.plans,
    required this.currentPlan,
    required this.refreshPlans,
    required this.upgradePlan,
    required this.cancelSubscription,
  });
}

class _SubscriptionHook extends Hook<SubscriptionHookState> {
  final String userId;

  const _SubscriptionHook(this.userId);

  @override
  HookState<SubscriptionHookState, Hook<SubscriptionHookState>>
      createState() => _SubscriptionHookState();
}

class _SubscriptionHookState
    extends HookState<SubscriptionHookState, _SubscriptionHook> {
  late ValueNotifier<bool> _isLoadingState;
  late ValueNotifier<List<SubscriptionPlan>> _plansState;
  late ValueNotifier<SubscriptionPlan?> _currentPlanState;

  final _getAvailablePlans = sl<GetAvailablePlansUseCase>();
  final _getCurrentSubscription = sl<GetCurrentSubscriptionUseCase>();
  final _upgradePlanUseCase = sl<UpgradePlanUseCase>();
  final _cancelSubscriptionUseCase = sl<CancelSubscriptionUseCase>();

  @override
  void initHook() {
    super.initHook();
    // Initialize ValueNotifiers directly
    _isLoadingState = ValueNotifier(true);
    _plansState = ValueNotifier([]);
    _currentPlanState = ValueNotifier(null);

    // Add listeners to trigger rebuilds when values change
    _isLoadingState.addListener(_onStateChanged);
    _plansState.addListener(_onStateChanged);
    _currentPlanState.addListener(_onStateChanged);

    _loadPlans();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Future<void> _loadPlans() async {
    _isLoadingState.value = true;
    try {
      final plans = await _getAvailablePlans();
      _plansState.value = plans;

      final subscription = await _getCurrentSubscription(hook.userId);
      final currentPlan = plans.firstWhere(
        (p) => p.type == subscription.currentPlan,
        orElse: () => plans.first,
      );
      _currentPlanState.value = currentPlan;
    } catch (e) {
      print('Error loading plans: $e');
    } finally {
      _isLoadingState.value = false;
    }
  }

  Future<bool> _upgradePlan(
    PlanType planType,
    PaymentMethod paymentMethod,
  ) async {
    _isLoadingState.value = true;
    try {
      await _upgradePlanUseCase(hook.userId, planType, paymentMethod);
      await _loadPlans();
      return true;
    } catch (e) {
      print('Error upgrading plan: $e');
      return false;
    } finally {
      _isLoadingState.value = false;
    }
  }

  Future<void> _cancelSub() async {
    _isLoadingState.value = true;
    try {
      await _cancelSubscriptionUseCase(hook.userId);
      await _loadPlans();
    } catch (e) {
      print('Error canceling subscription: $e');
    } finally {
      _isLoadingState.value = false;
    }
  }

  @override
  SubscriptionHookState build(context) {
    return SubscriptionHookState(
      isLoading: _isLoadingState.value,
      plans: _plansState.value,
      currentPlan: _currentPlanState.value,
      refreshPlans: _loadPlans,
      upgradePlan: _upgradePlan,
      cancelSubscription: _cancelSub,
    );
  }

  @override
  void dispose() {
    _isLoadingState.removeListener(_onStateChanged);
    _plansState.removeListener(_onStateChanged);
    _currentPlanState.removeListener(_onStateChanged);
    _isLoadingState.dispose();
    _plansState.dispose();
    _currentPlanState.dispose();
    super.dispose();
  }
}
