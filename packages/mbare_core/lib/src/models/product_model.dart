import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String vendorId,
    required String name,
    required String category,
    required double price,
    String? description,
    String? unit, // kg, piece, bunch, etc.
    @Default([]) List<String> images,
    @Default(0) int stockQuantity,
    @Default(true) bool isAvailable,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(_convertTimestamps(json));

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    // Handle Firestore Timestamp conversion
    if (converted['createdAt'] is Timestamp) {
      converted['createdAt'] =
          (converted['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (converted['updatedAt'] is Timestamp) {
      converted['updatedAt'] =
          (converted['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    return converted;
  }
}

extension ProductModelX on ProductModel {
  /// Returns formatted price (e.g., "$5.00")
  String get formattedPrice => '\$$price';

  /// Returns price with unit (e.g., "$5.00/kg")
  String get priceWithUnit => unit != null ? '$formattedPrice/$unit' : formattedPrice;

  /// Returns true if product is in stock
  bool get inStock => stockQuantity > 0 && isAvailable;

  /// Returns primary image URL or null
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  /// Returns stock status message
  String get stockStatus {
    if (!isAvailable) return 'Unavailable';
    if (stockQuantity == 0) return 'Out of stock';
    if (stockQuantity < 10) return 'Low stock';
    return 'In stock';
  }
}
