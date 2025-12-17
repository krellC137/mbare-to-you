import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mbare_core/src/models/product_model.dart';

part 'cart_item_model.freezed.dart';
part 'cart_item_model.g.dart';

@freezed
class CartItemModel with _$CartItemModel {
  const factory CartItemModel({
    required String productId,
    required String vendorId,
    required int quantity,
    required double unitPrice,
    String? productName,
    String? productImage,
    String? unit,
    DateTime? addedAt,
  }) = _CartItemModel;

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(_convertTimestamps(json));

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    // Handle Firestore Timestamp conversion
    if (converted['addedAt'] is Timestamp) {
      converted['addedAt'] =
          (converted['addedAt'] as Timestamp).toDate().toIso8601String();
    }
    return converted;
  }

  /// Create cart item from product
  factory CartItemModel.fromProduct({
    required ProductModel product,
    int quantity = 1,
  }) {
    return CartItemModel(
      productId: product.id,
      vendorId: product.vendorId,
      quantity: quantity,
      unitPrice: product.price,
      productName: product.name,
      productImage: product.primaryImage,
      unit: product.unit,
      addedAt: DateTime.now(),
    );
  }
}

extension CartItemModelX on CartItemModel {
  /// Calculate total price for this cart item
  double get totalPrice => unitPrice * quantity;

  /// Get formatted total price
  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';

  /// Get formatted unit price
  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
}
