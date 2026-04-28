# Guía Rápida - Sistema de Suscripción AirPulse

## 🚀 Inicio Rápido

### Paso 1: Acceder a la página de planes

Desde cualquier pantalla, navega a la página de planes:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PricingPage(userId: currentUserId),
  ),
);
```

### Paso 2: Agregar botón "Actualizar Plan"

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingPage(userId: userId),
      ),
    );
  },
  child: const Text('Actualizar Plan'),
)
```

### Paso 3: Bloquear características

```dart
FeatureGuard(
  userId: userId,
  featureName: 'offline_mode',  // 'quality_selection', 'playlist_sharing', etc.
  featureDisplayName: 'Descargas',
  child: YourFeature(),
)
```

## 📊 Planes Disponibles

| Plan | Precio | Principales |
|------|--------|---|
| 🆓 Gratuito | $0 | Acceso básico, anuncios |
| ⭐ Starter | $1 | Sin anuncios, descargas, offline |
| 🎵 Pro | $3 | Calidad alta, compartir playlists |
| 👑 Premium | $5 | **Más popular** - Lossless, soporte |
| 💎 Elite | $10 | Máximo - Hi-Fi, Dolby, familia |

## 🔧 Configuración de Pagos

### Stripe (Tarjeta)
1. Ve a `services/payment_service.dart`
2. Reemplaza:
```dart
static const String _stripePublishableKey = 'pk_live_YOUR_KEY';
```

### PayPal
1. Ve a `services/payment_service.dart`
2. Reemplaza:
```dart
static const String _paypalClientId = 'YOUR_CLIENT_ID';
```

## 📝 Características por Plan

### Offline Mode (Descargas)
```dart
FeatureGuard(
  userId: userId,
  featureName: 'offline_mode',
  featureDisplayName: 'Descargas y Modo Offline',
  child: DownloadButton(),
)
```
Disponible en: Starter+ 

### Quality Selection (Calidad)
```dart
FeatureGuard(
  userId: userId,
  featureName: 'quality_selection',
  featureDisplayName: 'Selección de Calidad',
  child: QualityDropdown(),
)
```
Disponible en: Pro+

### Playlist Sharing
Disponible en: Pro+

### Advanced Search
Disponible en: Premium+

### Remove Ads (Sin Anuncios)
Disponible en: Starter+

## 🎯 Casos de Uso Comunes

### Mostrar Plan Actual

```dart
final subscription = useSubscription(userId);
Text('Plan: ${subscription.currentPlan?.name}')
```

### Verificar si Característica Disponible

```dart
final hasFeature = useIsFeatureAvailable(userId, 'offline_mode');
if (hasFeature) {
  // Mostrar característica
}
```

### Mostrar Botón Condicional

```dart
final subscription = useSubscription(userId);
if (subscription.currentPlan?.type == PlanType.free) {
  ElevatedButton(
    onPressed: () => navigateToPricing(userId),
    child: const Text('Actualizar'),
  )
}
```

## 💳 Métodos de Pago Soportados

✅ Tarjeta de Crédito (Visa, Mastercard, etc.)
✅ PayPal
✅ Tarjeta de Débito

Cada método tiene validación automática:
- Números de tarjeta: Algoritmo de Luhn
- CVV: 3-4 dígitos
- Email PayPal: Validación de formato

## 🧪 Testing

### Tarjetas de Prueba
- **Visa**: 4532 0123 4567 8901
- **Mastercard**: 5425 2334 3010 9903

### Datos de Prueba
- CVV: 123
- Fecha: 12/25
- Titular: Test User

## 📱 Integración en UI Existente

### En Barra de Reproductor
```dart
if (currentPlan?.type == PlanType.free)
  ElevatedButton.icon(
    onPressed: () => navigateToPricing(),
    icon: const Icon(Icons.upgrade),
    label: const Text('Actualizar'),
  )
```

### En Menú Lateral
```dart
ListTile(
  title: const Text('Planes de Suscripción'),
  onTap: () => navigateToPricing(),
)
```

### En Biblioteca
Agrupa características premium con `FeatureGuard`

## ❓ Preguntas Frecuentes

**¿Cómo cambiar el plan?**
El usuario va a `PricingPage` y selecciona un nuevo plan. El sistema actualiza automáticamente.

**¿Dónde se guardan los datos?**
En `SharedPreferences` localmente. En producción, debe ir a un servidor backend.

**¿Cómo agregar nuevas características?**
1. Agregar parámetro en `SubscriptionPlan`
2. Agregar lógica en `_checkFeatureAvailability`
3. Usar con `FeatureGuard`

**¿Cómo personalizar los planes?**
Modifica `SubscriptionPlan.getAllPlans()` en `subscription_plan.dart`

## 📚 Documentación Completa

Ver `SUBSCRIPTION_SYSTEM.md` para documentación detallada.

## 💡 Tips

- El botón "Actualizar Plan" aparece automáticamente en planes gratuitos
- Premium está marcado como "Más Popular" en la UI
- Los planes se cargan desde `SubscriptionPlan.getAllPlans()`
- El almacenamiento actual usa `SharedPreferences`, migra a backend en producción
- Los pagos son simulados, integra con Stripe/PayPal APIs en producción

---

**¿Necesitas ayuda?** Revisa los ejemplos en `SUBSCRIPTION_INTEGRATION_EXAMPLES.dart`
