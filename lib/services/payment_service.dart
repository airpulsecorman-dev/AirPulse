import 'dart:async';
import 'package:airpulse/domain/entities/subscription_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado del pago
class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;
  final String? errorCode;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
    this.errorCode,
  });

  factory PaymentResult.success(String transactionId) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: 'Pago completado exitosamente',
    );
  }

  factory PaymentResult.failure(String message, {String? errorCode}) {
    return PaymentResult(
      success: false,
      transactionId: '',
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Servicio de pagos con soporte para Stripe y PayPal
class PaymentService {
  // Claves de configuración - Reemplazar con tus credenciales reales
  // static const String _stripePublishableKey = 'pk_test_YOUR_STRIPE_KEY_HERE';
  // static const String _stripeSecretKey = 'sk_test_YOUR_STRIPE_SECRET_HERE';
  // static const String _paypalClientId = 'YOUR_PAYPAL_CLIENT_ID_HERE';
  // static const String _paypalSecret = 'YOUR_PAYPAL_SECRET_HERE';
  
  final SharedPreferences _prefs;

  PaymentService(this._prefs);

  /// Procesa un pago con tarjeta de crédito usando Stripe
  Future<PaymentResult> processCardPayment({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required double amount,
    required String currency,
    required String planName,
  }) async {
    try {
      // Validar datos de tarjeta
      if (!_validateCardNumber(cardNumber)) {
        return PaymentResult.failure(
          'Número de tarjeta inválido',
          errorCode: 'invalid_card_number',
        );
      }

      if (!_validateCVV(cvv)) {
        return PaymentResult.failure(
          'CVV inválido',
          errorCode: 'invalid_cvv',
        );
      }

      // Simular procesamiento de Stripe
      // En producción, esto usaría la API de Stripe
      final transactionId = _generateTransactionId('stripe');
      
      // Guardar en SharedPreferences
      await _saveTransaction(
        transactionId: transactionId,
        amount: amount,
        paymentMethod: PaymentMethod.creditCard,
        planName: planName,
        status: 'completed',
      );

      return PaymentResult.success(transactionId);
    } catch (e) {
      return PaymentResult.failure(
        'Error al procesar el pago: ${e.toString()}',
        errorCode: 'payment_error',
      );
    }
  }

  /// Procesa un pago con PayPal
  Future<PaymentResult> processPayPalPayment({
    required String email,
    required double amount,
    required String currency,
    required String planName,
  }) async {
    try {
      // Validar email
      if (!_validateEmail(email)) {
        return PaymentResult.failure(
          'Email inválido',
          errorCode: 'invalid_email',
        );
      }

      // Simular procesamiento de PayPal
      // En producción, esto usaría la API de PayPal
      final transactionId = _generateTransactionId('paypal');

      // Guardar en SharedPreferences
      await _saveTransaction(
        transactionId: transactionId,
        amount: amount,
        paymentMethod: PaymentMethod.paypal,
        planName: planName,
        status: 'completed',
      );

      return PaymentResult.success(transactionId);
    } catch (e) {
      return PaymentResult.failure(
        'Error al procesar PayPal: ${e.toString()}',
        errorCode: 'paypal_error',
      );
    }
  }

  /// Procesa un pago con tarjeta de débito
  Future<PaymentResult> processDebitPayment({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required String bankName,
    required double amount,
    required String currency,
    required String planName,
  }) async {
    try {
      // Validar datos de tarjeta de débito
      if (!_validateCardNumber(cardNumber)) {
        return PaymentResult.failure(
          'Número de tarjeta inválido',
          errorCode: 'invalid_card_number',
        );
      }

      final transactionId = _generateTransactionId('debit');

      await _saveTransaction(
        transactionId: transactionId,
        amount: amount,
        paymentMethod: PaymentMethod.debitCard,
        planName: planName,
        status: 'completed',
      );

      return PaymentResult.success(transactionId);
    } catch (e) {
      return PaymentResult.failure(
        'Error al procesar pago de débito: ${e.toString()}',
        errorCode: 'debit_error',
      );
    }
  }

  /// Obtiene el historial de transacciones
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    final transactions = _prefs.getStringList('transactions') ?? [];
    return transactions
        .map((t) => Map<String, dynamic>.from(
          {'transactionData': t}, // Simplificado para este ejemplo
        ))
        .toList();
  }

  /// Reembolsa una transacción
  Future<bool> refundTransaction(String transactionId) async {
    try {
      // Simular reembolso
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Valida un número de tarjeta usando el algoritmo de Luhn
  bool _validateCardNumber(String cardNumber) {
    if (cardNumber.isEmpty || cardNumber.length < 13 || cardNumber.length > 19) {
      return false;
    }

    // Algoritmo de Luhn
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  /// Valida un CVV
  bool _validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv);
  }

  /// Valida un email
  bool _validateEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Genera un ID de transacción único
  String _generateTransactionId(String provider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${provider}_${timestamp}_${DateTime.now().microsecond}';
  }

  /// Guarda una transacción en el almacenamiento local
  Future<void> _saveTransaction({
    required String transactionId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String planName,
    required String status,
  }) async {
    final transactions = _prefs.getStringList('transactions') ?? [];
    
    final transactionData = {
      'id': transactionId,
      'amount': amount,
      'method': paymentMethod.toString(),
      'plan': planName,
      'status': status,
      'date': DateTime.now().toIso8601String(),
    };

    transactions.add(transactionData.toString());
    await _prefs.setStringList('transactions', transactions);
  }
}
