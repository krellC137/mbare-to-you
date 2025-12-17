import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

/// Review type enum
enum ReviewType {
  product,
  vendor,
  driver,
}

/// Review model for products, vendors, and drivers
@freezed
class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    String? id,
    required String orderId, // Order associated with this review
    required String userId, // Customer who wrote the review
    required String userName,
    String? userPhoto,
    required String targetId, // Product/Vendor/Driver ID being reviewed
    required ReviewType type, // Type of review
    required int rating, // 1-5
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ReviewModel;

  const ReviewModel._();

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(_convertTimestamps(json));

  /// Convert to Firestore-compatible JSON
  Map<String, dynamic> toFirestoreJson() {
    final json = toJson();
    if (createdAt != null) {
      json['createdAt'] = Timestamp.fromDate(createdAt!);
    }
    if (updatedAt != null) {
      json['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    return json;
  }

  /// Check if review has comment
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Get rating as double for calculations
  double get ratingDouble => rating.toDouble();
}

/// Helper to convert Firestore Timestamps to DateTime
Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
  final result = Map<String, dynamic>.from(json);

  if (result['createdAt'] is Timestamp) {
    result['createdAt'] =
        (result['createdAt'] as Timestamp).toDate().toIso8601String();
  }
  if (result['updatedAt'] is Timestamp) {
    result['updatedAt'] =
        (result['updatedAt'] as Timestamp).toDate().toIso8601String();
  }

  return result;
}
