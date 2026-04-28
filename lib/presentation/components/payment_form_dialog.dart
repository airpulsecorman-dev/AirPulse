import 'package:flutter/material.dart';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:airpulse/services/payment_service.dart';

/// Diálogo de pago con soporte para tarjeta de crédito y PayPal
class PaymentFormDialog extends StatefulWidget {
  final SubscriptionPlan plan;
  final PaymentService paymentService;
  final Function(bool success, String transactionId) onPaymentComplete;

  const PaymentFormDialog({
    super.key,
    required this.plan,
    required this.paymentService,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  late PageController _pageController;
  int _currentPage = 0;
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;

  // Formulario de tarjeta
  late TextEditingController _cardNumberController;
  late TextEditingController _cardHolderController;
  late TextEditingController _expiryMonthController;
  late TextEditingController _expiryYearController;
  late TextEditingController _cvvController;

  // Formulario de PayPal
  late TextEditingController _paypalEmailController;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cardNumberController = TextEditingController();
    _cardHolderController = TextEditingController();
    _expiryMonthController = TextEditingController();
    _expiryYearController = TextEditingController();
    _cvvController = TextEditingController();
    _paypalEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _paypalEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() => _currentPage = page);
          },
          children: [
            _buildMethodSelection(),
            if (_selectedMethod == PaymentMethod.creditCard ||
                _selectedMethod == PaymentMethod.debitCard)
              _buildCardForm()
            else
              _buildPayPalForm(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_currentPage == 0)
          ElevatedButton(
            onPressed: _selectedMethod == PaymentMethod.paypal
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.black),
            ),
          )
        else
          ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isProcessing ? Colors.grey : Colors.amber,
            ),
            child: Text(
              _isProcessing ? 'Procesando...' : 'Pagar',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMethodSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Método de Pago',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \$${widget.plan.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
          const SizedBox(height: 24),
          _buildPaymentMethodTile(
            PaymentMethod.creditCard,
            'Tarjeta de Crédito',
            Icons.credit_card,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodTile(
            PaymentMethod.paypal,
            'PayPal',
            Icons.payment,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodTile(
            PaymentMethod.debitCard,
            'Tarjeta de Débito',
            Icons.credit_card,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedMethod == method ? Colors.amber : Colors.grey[700]!,
            width: _selectedMethod == method ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedMethod == method
              ? Colors.amber.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedMethod == method ? Colors.amber : Colors.grey[400],
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: _selectedMethod == method ? Colors.amber : Colors.grey[300],
                fontWeight: _selectedMethod == method
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_selectedMethod == method)
              const Icon(
                Icons.check_circle,
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedMethod == PaymentMethod.creditCard
                  ? 'Datos de Tarjeta de Crédito'
                  : 'Datos de Tarjeta de Débito',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _cardNumberController,
              label: 'Número de Tarjeta',
              hint: '4532 1234 5678 9010',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cardHolderController,
              label: 'Titular',
              hint: 'John Doe',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryMonthController,
                    label: 'Mes',
                    hint: 'MM',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _expiryYearController,
                    label: 'Año',
                    hint: 'YY',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '123',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayPalForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos de PayPal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _paypalEmailController,
            label: 'Correo de PayPal',
            hint: 'email@example.com',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Serás redirigido a PayPal para completar la transacción de forma segura.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[300],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      late PaymentResult result;

      if (_selectedMethod == PaymentMethod.creditCard) {
        result = await widget.paymentService.processCardPayment(
          cardNumber: _cardNumberController.text,
          expiryMonth: _expiryMonthController.text,
          expiryYear: _expiryYearController.text,
          cvv: _cvvController.text,
          cardHolderName: _cardHolderController.text,
          amount: widget.plan.price,
          currency: widget.plan.currency,
          planName: widget.plan.name,
        );
      } else if (_selectedMethod == PaymentMethod.paypal) {
        result = await widget.paymentService.processPayPalPayment(
          email: _paypalEmailController.text,
          amount: widget.plan.price,
          currency: widget.plan.currency,
          planName: widget.plan.name,
        );
      } else {
        result = await widget.paymentService.processDebitPayment(
          cardNumber: _cardNumberController.text,
          expiryMonth: _expiryMonthController.text,
          expiryYear: _expiryYearController.text,
          cvv: _cvvController.text,
          cardHolderName: _cardHolderController.text,
          bankName: '',
          amount: widget.plan.price,
          currency: widget.plan.currency,
          planName: widget.plan.name,
        );
      }

      widget.onPaymentComplete(result.success, result.transactionId);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
