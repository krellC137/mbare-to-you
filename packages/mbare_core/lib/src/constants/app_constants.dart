/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App information
  static const String appName = 'MbareToYou';
  static const String appVersion = '1.0.0';

  /// API & Backend
  static const String baseUrl = 'https://api.mbaretoyou.co.zw';
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Image & Media
  static const int maxImageSizeMB = 5;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImagesPerProduct = 5;

  /// Order & Delivery
  static const double minOrderAmount = 5.0;
  static const double baseDeliveryFee = 1.0;
  static const double deliveryFeePerKm = 0.5;
  static const int maxDeliveryDistanceKm = 20;

  /// Cache durations (in seconds)
  static const int shortCacheDuration = 300; // 5 minutes
  static const int mediumCacheDuration = 1800; // 30 minutes
  static const int longCacheDuration = 86400; // 24 hours

  /// User roles
  static const String roleCustomer = 'customer';
  static const String roleVendor = 'vendor';
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';

  /// Order status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusPickedUp = 'picked_up';
  static const String orderStatusInTransit = 'in_transit';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  /// Payment status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusProcessing = 'processing';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  /// Payment methods
  static const String paymentMethodEcocash = 'ecocash';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodCash = 'cash';

  /// Market sections (Mbare Musika)
  static const List<String> marketSections = [
    'Section A',
    'Section B',
    'Section C',
    'Section D',
    'Makoronyera',
  ];

  /// Product categories
  static const List<String> productCategories = [
    'Vegetables',
    'Fruits',
    'Grains & Cereals',
    'Herbs & Spices',
    'Roots & Tubers',
    'Other',
  ];

  /// Support
  static const String supportEmail = 'support@mbaretoyou.co.zw';
  static const String supportPhone = '+263771234567';
}
