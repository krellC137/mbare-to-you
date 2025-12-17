import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_model.freezed.dart';
part 'vendor_model.g.dart';

@freezed
class VendorModel with _$VendorModel {
  const factory VendorModel({
    required String id,
    required String ownerId,
    required String businessName,
    required String tableNumber,
    required String marketSection,
    String? description,
    String? logoUrl,
    String? phoneNumber,
    String? email,
    @Default(false) bool isApproved,
    @Default(true) bool isActive,
    @Default(0.0) double rating,
    @Default(0) int totalReviews,
    @Default(0) int totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _VendorModel;

  factory VendorModel.fromJson(Map<String, dynamic> json) =>
      _$VendorModelFromJson(_convertTimestamps(json));

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

extension VendorModelX on VendorModel {
  /// Returns vendor display name
  String get displayName => businessName;

  /// Returns formatted table number with section
  String get tableLocation => 'Table $tableNumber, $marketSection';

  /// Returns true if vendor can accept orders
  bool get canAcceptOrders => isApproved && isActive;

  /// Returns rating display (e.g., "4.5")
  String get ratingDisplay => rating.toStringAsFixed(1);
}
