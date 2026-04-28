import 'package:equatable/equatable.dart';

/// Enumeración de tipos de planes disponibles
enum PlanType {
  free,
  starter,
  pro,
  premium,
  elite,
}

/// Enumeración de métodos de pago
enum PaymentMethod {
  creditCard,
  paypal,
  debitCard,
}

/// Entidad que representa un plan de suscripción
class SubscriptionPlan extends Equatable {
  final PlanType type;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<String> features;
  final bool isPopular;
  final int storageGB;
  final bool supportsOfflineMode;
  final bool supportsQualitySelection;
  final bool supportsPlaylistSharing;
  final bool supportsAdvancedSearch;
  final bool removeAds;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.features,
    this.isPopular = false,
    this.storageGB = 1,
    this.supportsOfflineMode = false,
    this.supportsQualitySelection = false,
    this.supportsPlaylistSharing = false,
    this.supportsAdvancedSearch = false,
    this.removeAds = false,
  });

  /// Crea un plan gratuito
  factory SubscriptionPlan.free() {
    return SubscriptionPlan(
      type: PlanType.free,
      name: 'Gratuito',
      description: 'Disfruta música con limitaciones',
      price: 0,
      currency: '\$',
      storageGB: 1,
      features: [
        'Acceso a biblioteca',
        'Reproducción básica',
        'Anuncios incluidos',
        'Calidad estándar',
      ],
    );
  }

  /// Crea un plan starter
  factory SubscriptionPlan.starter() {
    return SubscriptionPlan(
      type: PlanType.starter,
      name: 'Starter',
      description: 'Para empezar',
      price: 1.0,
      currency: '\$',
      storageGB: 5,
      supportsOfflineMode: true,
      features: [
        'Todo del plan Gratuito',
        'Descarga de canciones',
        'Modo sin conexión',
        'Sin anuncios',
      ],
    );
  }

  /// Crea un plan pro
  factory SubscriptionPlan.pro() {
    return SubscriptionPlan(
      type: PlanType.pro,
      name: 'Pro',
      description: 'Para usuarios activos',
      price: 3.0,
      currency: '\$',
      storageGB: 25,
      supportsOfflineMode: true,
      supportsQualitySelection: true,
      supportsPlaylistSharing: true,
      features: [
        'Todo del plan Starter',
        'Calidad alta (320 kbps)',
        'Compartir playlists',
        'Búsqueda avanzada',
        'Historial sin límite',
      ],
    );
  }

  /// Crea un plan premium
  factory SubscriptionPlan.premium() {
    return SubscriptionPlan(
      type: PlanType.premium,
      name: 'Premium',
      description: 'Experiencia premium',
      price: 5.0,
      currency: '\$',
      isPopular: true,
      storageGB: 50,
      supportsOfflineMode: true,
      supportsQualitySelection: true,
      supportsPlaylistSharing: true,
      supportsAdvancedSearch: true,
      removeAds: true,
      features: [
        'Todo del plan Pro',
        'Calidad lossless',
        'Descargas ilimitadas',
        'Estadísticas detalladas',
        'Recomendaciones personalizadas',
        'Soporte prioritario',
      ],
    );
  }

  /// Crea un plan elite
  factory SubscriptionPlan.elite() {
    return SubscriptionPlan(
      type: PlanType.elite,
      name: 'Elite',
      description: 'Lo máximo en audio',
      price: 10.0,
      currency: '\$',
      storageGB: 200,
      supportsOfflineMode: true,
      supportsQualitySelection: true,
      supportsPlaylistSharing: true,
      supportsAdvancedSearch: true,
      removeAds: true,
      features: [
        'Todo del plan Premium',
        'Audio Hi-Fi sin pérdida',
        'Espacializador Dolby',
        'Ecualizador avanzado',
        'Análisis de audio profundo',
        'Acceso a contenido exclusivo',
        'Soporte 24/7',
        'Familia (hasta 5 cuentas)',
      ],
    );
  }

  /// Obtiene una lista de todos los planes disponibles
  static List<SubscriptionPlan> getAllPlans() {
    return [
      SubscriptionPlan.free(),
      SubscriptionPlan.starter(),
      SubscriptionPlan.pro(),
      SubscriptionPlan.premium(),
      SubscriptionPlan.elite(),
    ];
  }

  @override
  List<Object?> get props => [
        type,
        name,
        description,
        price,
        currency,
        features,
        isPopular,
        storageGB,
        supportsOfflineMode,
        supportsQualitySelection,
        supportsPlaylistSharing,
        supportsAdvancedSearch,
        removeAds,
      ];
}
