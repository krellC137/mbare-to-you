import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_model.freezed.dart';
part 'payment_method_model.g.dart';

/// Payment method type
enum PaymentMethodType {
  card,
  mobileMoney,
  cash,
}

@freezed
class PaymentMethodModel with _$PaymentMethodModel {
  const factory PaymentMethodModel({
    String? id,
    required String userId,
    required PaymentMethodType type,
    String? cardholderName,
    String? cardNumber, // Last 4 digits only
    String? cardExpiry, // MM/YY format
    String? mobileMoneyProvider, // EcoCash, OneMoney, etc.
    String? mobileMoneyNumber,
    @Default(false) bool isDefault,
    DateTime? createdAt,
  }) = _PaymentMethodModel;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodModelFromJson(_convertTimestamps(json));

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    // Handle Firestore Timestamp conversion
    if (converted['createdAt'] is Timestamp) {
      converted['createdAt'] =
          (converted['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return converted;
  }
}

extension PaymentMethodModelX on PaymentMethodModel {
  /// Returns display name for the payment method
  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return cardholderName ?? 'Card ending in ${cardNumber ?? '****'}';
      case PaymentMethodType.mobileMoney:
        return '$mobileMoneyProvider ${mobileMoneyNumber ?? ''}';
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
    }
  }

  /// Returns icon name for the payment method
  String get iconName {
    switch (type) {
      case PaymentMethodType.card:
        return 'credit_card';
      case PaymentMethodType.mobileMoney:
        return 'phone_android';
      case PaymentMethodType.cash:
        return 'money';
    }
  }

  /// Returns masked card number
  String get maskedCardNumber {
    if (cardNumber == null) return '****';
    return '**** **** **** $cardNumber';
  }
}
