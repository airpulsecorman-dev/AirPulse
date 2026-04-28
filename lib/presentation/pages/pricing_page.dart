import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/presentation/hooks/use_subscription.dart';

class PricingPage extends HookWidget {
  final String userId;

  const PricingPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes de Suscripción'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      backgroundColor: const Color(0xFF16213E),
      body: subscription.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                // Encabezado
                Text(
                  'Elige tu plan perfecto',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu plan actual: ${subscription.currentPlan?.name ?? 'Cargando...'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Planes
                ...subscription.plans.asMap().entries.map((entry) {
                  final plan = entry.value;
                  final isCurrent =
                      subscription.currentPlan?.type == plan.type;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 16,
                      left: plan.isPopular ? 0 : 8,
                      right: plan.isPopular ? 0 : 8,
                    ),
                    child: _PlanCard(
                      plan: plan,
                      isCurrent: isCurrent,
                      isPopular: plan.isPopular,
                      onUpgrade: () {
                        _showPaymentDialog(
                          context,
                          plan,
                          subscription,
                        );
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionHookState subscription,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PaymentDialog(
        plan: plan,
        onPaymentMethod: (method) {
          _processPayment(context, plan, method, subscription);
        },
      ),
    );
  }

  void _processPayment(
    BuildContext context,
    SubscriptionPlan plan,
    PaymentMethod method,
    SubscriptionHookState subscription,
  ) {
    // Simular procesamiento de pago
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pago procesado para ${plan.name}'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Llamar al upgrade
    subscription.upgradePlan(plan.type, method).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Plan actualizado a ${plan.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}

/// Widget de tarjeta de plan
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isPopular;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isPopular,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isPopular
            ? Border.all(color: Colors.amber, width: 2)
            : Border.all(color: Colors.grey[700]!, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: isPopular ? const Color(0xFF0F3460) : const Color(0xFF0F3460),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Más Popular',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (isCurrent)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Plan Actual',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del plan
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                // Descripción
                Text(
                  plan.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                const SizedBox(height: 16),
                // Precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.price == 0
                          ? 'Gratis'
                          : '\$${plan.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (plan.price > 0)
                      Text(
                        '/mes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Características
                ...plan.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[400],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[300],
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                // Botón de acción
                if (isCurrent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Plan Actual',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      plan.price == 0 ? 'Cambiar a Gratuito' : 'Actualizar Plan',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de método de pago
class _PaymentDialog extends StatefulWidget {
  final SubscriptionPlan plan;
  final Function(PaymentMethod) onPaymentMethod;

  const _PaymentDialog({
    required this.plan,
    required this.onPaymentMethod,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PaymentMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text(
        'Selecciona Método de Pago',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total: \$${widget.plan.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[300],
                ),
          ),
          const SizedBox(height: 24),
          _PaymentMethodOption(
            method: PaymentMethod.creditCard,
            title: 'Tarjeta de Crédito',
            icon: Icons.credit_card,
            selected: _selectedMethod == PaymentMethod.creditCard,
            onTap: () {
              setState(() => _selectedMethod = PaymentMethod.creditCard);
            },
          ),
          const SizedBox(height: 12),
          _PaymentMethodOption(
            method: PaymentMethod.paypal,
            title: 'PayPal',
            icon: Icons.payment,
            selected: _selectedMethod == PaymentMethod.paypal,
            onTap: () {
              setState(() => _selectedMethod = PaymentMethod.paypal);
            },
          ),
          const SizedBox(height: 12),
          _PaymentMethodOption(
            method: PaymentMethod.debitCard,
            title: 'Tarjeta de Débito',
            icon: Icons.credit_card,
            selected: _selectedMethod == PaymentMethod.debitCard,
            onTap: () {
              setState(() => _selectedMethod = PaymentMethod.debitCard);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedMethod != null
              ? () {
                  widget.onPaymentMethod(_selectedMethod!);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
          ),
          child: const Text(
            'Continuar',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}

/// Opción de método de pago
class _PaymentMethodOption extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.method,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.amber : Colors.grey[700]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? Colors.amber.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.amber : Colors.grey[400],
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.amber : Colors.grey[300],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(
                Icons.check_circle,
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }
}
