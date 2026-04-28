# Sistema de Suscripción AirPulse

## Descripción General

Se ha implementado un sistema completo de planes de suscripción para AirPulse con soporte para:
- **Plan Gratuito**: Acceso básico sin costo
- **Planes de Pago**: Starter ($1), Pro ($3), Premium ($5), Elite ($10)
- **Métodos de Pago**: Tarjeta de Crédito, PayPal, Tarjeta de Débito
- **Control de Características**: Bloquea/desbloquea funciones según el plan

## Estructura de Archivos

```
lib/
├── domain/
│   ├── entities/
│   │   ├── subscription_plan.dart      # Entidad del plan de suscripción
│   │   └── user_subscription.dart      # Entidad de suscripción del usuario
│   ├── repositories/
│   │   └── subscription_repository.dart # Interfaz del repositorio
│   └── usecases/
│       └── subscription_usecases.dart   # Casos de uso
│
├── data/
│   ├── models/
│   │   └── subscription_model.dart     # Modelos de datos
│   └── repositories/
│       └── subscription_repository_impl.dart # Implementación del repositorio
│
├── presentation/
│   ├── pages/
│   │   └── pricing_page.dart           # Página de planes de precios
│   ├── components/
│   │   ├── feature_guard.dart          # Widget de bloqueo de características
│   │   └── payment_form_dialog.dart    # Diálogo de pago
│   └── hooks/
│       └── use_subscription.dart       # Hook personalizado
│
└── services/
    └── payment_service.dart            # Servicio de pagos
```

## Planes Disponibles

### Plan Gratuito
- **Precio**: Gratis
- **Características**:
  - Acceso a biblioteca
  - Reproducción básica
  - Anuncios incluidos
  - Calidad estándar
- **Almacenamiento**: 1 GB

### Plan Starter ($1/mes)
- **Características adicionales**:
  - Sin anuncios
  - Descargas de canciones
  - Modo sin conexión
- **Almacenamiento**: 5 GB

### Plan Pro ($3/mes)
- **Características adicionales**:
  - Calidad alta (320 kbps)
  - Compartir playlists
  - Búsqueda avanzada
- **Almacenamiento**: 25 GB

### Plan Premium ($5/mes) - Recomendado
- **Características adicionales**:
  - Calidad lossless
  - Descargas ilimitadas
  - Estadísticas detalladas
  - Recomendaciones personalizadas
  - Soporte prioritario
- **Almacenamiento**: 50 GB

### Plan Elite ($10/mes)
- **Características adicionales**:
  - Audio Hi-Fi sin pérdida
  - Espacializador Dolby
  - Ecualizador avanzado
  - Análisis de audio profundo
  - Acceso a contenido exclusivo
  - Soporte 24/7
  - Familia (hasta 5 cuentas)
- **Almacenamiento**: 200 GB

## Integración

### 1. Agregar al main.dart (si no está)

```dart
import 'package:airpulse/presentation/pages/pricing_page.dart';

// En tu navegación, agrega la ruta a PricingPage
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PricingPage(userId: currentUserId),
  ),
);
```

### 2. Bloquear características con FeatureGuard

```dart
FeatureGuard(
  userId: userId,
  featureName: 'offline_mode',
  featureDisplayName: 'Descargas y Modo Sin Conexión',
  child: YourFeatureWidget(),
)
```

### 3. Usar el Hook de Suscripción

```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final subscription = useSubscription(userId);

    return Column(
      children: [
        Text('Plan Actual: ${subscription.currentPlan?.name}'),
        if (!subscription.isLoading)
          ElevatedButton(
            onPressed: () => subscription.upgradePlan(
              PlanType.pro,
              PaymentMethod.creditCard,
            ),
            child: const Text('Actualizar Plan'),
          ),
      ],
    );
  }
}
```

## Métodos de Pago

### Tarjeta de Crédito/Débito
- Validación de número con algoritmo de Luhn
- Validación de CVV
- Validación de fecha de expiración

### PayPal
- Integración segura
- Redirección a PayPal para completar transacción
- Confirmación automática

## Validaciones

- **Número de Tarjeta**: Mínimo 13, máximo 19 dígitos (algoritmo Luhn)
- **CVV**: 3 o 4 dígitos
- **Email PayPal**: Formato válido de correo

## Características Bloqueadas por Plan

| Característica | Free | Starter | Pro | Premium | Elite |
|---|---|---|---|---|---|
| Modo Offline | ❌ | ✅ | ✅ | ✅ | ✅ |
| Selección de Calidad | ❌ | ❌ | ✅ | ✅ | ✅ |
| Compartir Playlists | ❌ | ❌ | ✅ | ✅ | ✅ |
| Búsqueda Avanzada | ❌ | ❌ | ❌ | ✅ | ✅ |
| Sin Anuncios | ❌ | ✅ | ✅ | ✅ | ✅ |
| Almacenamiento | 1GB | 5GB | 25GB | 50GB | 200GB |

## Configuración de Claves de API

### Para Stripe (Tarjeta de Crédito)
En `services/payment_service.dart`, reemplaza:
```dart
static const String _stripePublishableKey = 'pk_live_YOUR_KEY_HERE';
static const String _stripeSecretKey = 'sk_live_YOUR_KEY_HERE';
```

### Para PayPal
En `services/payment_service.dart`, reemplaza:
```dart
static const String _paypalClientId = 'YOUR_CLIENT_ID_HERE';
static const String _paypalSecret = 'YOUR_SECRET_HERE';
```

## Almacenamiento Local

Los datos de suscripción se almacenan en `SharedPreferences`:
- `user_subscription_{userId}`: Datos de suscripción actual
- `transactions`: Historial de transacciones

## Flujo de Pago

1. Usuario selecciona plan en `PricingPage`
2. Se abre diálogo de selección de método de pago
3. Usuario completa formulario de pago
4. `PaymentService` procesa la transacción
5. Si es exitoso, `SubscriptionRepository` actualiza datos
6. UI se actualiza con nuevo plan

## Testing

### Tarjetas de Prueba (Stripe)
- **Visa**: 4532 0123 4567 8901
- **Mastercard**: 5425 2334 3010 9903

### Usuario de Prueba PayPal
- Email: sb-account@paypal.com
- Contraseña: 123456

## Notas Importantes

1. **Seguridad**: En producción, usa HTTPS y valida todas las transacciones en el servidor
2. **Backend**: Implementa un servidor que maneje las transacciones y sincronize con base de datos
3. **Webhooks**: Configura webhooks para confirmar transacciones exitosas
4. **Renovación Automática**: Implementa sistema de renovación automática de suscripciones
5. **Reembolsos**: Implementa lógica de reembolsos si es necesario

## Próximas Mejoras

- [ ] Integración real con Stripe API
- [ ] Integración real con PayPal API
- [ ] Sincronización con backend
- [ ] Renovación automática de suscripciones
- [ ] Historial de transacciones completo
- [ ] Cambio de plan durante suscripción
- [ ] Sistema de cupones/descuentos
- [ ] Planes anuales con descuento
