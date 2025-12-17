import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_settings_model.freezed.dart';
part 'platform_settings_model.g.dart';

@freezed
class PlatformSettingsModel with _$PlatformSettingsModel {
  const PlatformSettingsModel._();

  const factory PlatformSettingsModel({
    required String id,
    @Default(10.0) double deliveryFeePercentage,
    @Default(5.0) double platformFeePercentage,
    @Default(0.0) double minimumOrderAmount,
    @Default(5.0) double baseDeliveryFee,
    @Default(true) bool isDeliveryFeePercentageBased,
    DateTime? updatedAt,
    String? updatedBy,
  }) = _PlatformSettingsModel;

  factory PlatformSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$PlatformSettingsModelFromJson(_convertTimestamps(json));

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    // Handle Firestore Timestamp conversion
    if (converted['updatedAt'] is Timestamp) {
      converted['updatedAt'] =
          (converted['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    return converted;
  }

  /// Calculate delivery fee based on subtotal
  double calculateDeliveryFee(double subtotal) {
    if (isDeliveryFeePercentageBased) {
      final percentageFee = subtotal * (deliveryFeePercentage / 100);
      return percentageFee < baseDeliveryFee ? baseDeliveryFee : percentageFee;
    }
    return baseDeliveryFee;
  }

  /// Calculate platform fee based on subtotal
  double calculatePlatformFee(double subtotal) {
    return subtotal * (platformFeePercentage / 100);
  }

  /// Calculate total with all fees
  double calculateTotal(double subtotal) {
    final deliveryFee = calculateDeliveryFee(subtotal);
    return subtotal + deliveryFee;
  }

  /// Get formatted delivery fee percentage
  String get formattedDeliveryFeePercentage =>
      '${deliveryFeePercentage.toStringAsFixed(1)}%';

  /// Get formatted platform fee percentage
  String get formattedPlatformFeePercentage =>
      '${platformFeePercentage.toStringAsFixed(1)}%';

  /// Get formatted base delivery fee
  String get formattedBaseDeliveryFee =>
      '\$${baseDeliveryFee.toStringAsFixed(2)}';

  /// Get formatted minimum order amount
  String get formattedMinimumOrderAmount =>
      '\$${minimumOrderAmount.toStringAsFixed(2)}';
}
