import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_model.freezed.dart';
part 'favorite_model.g.dart';

/// Favorite item type
enum FavoriteType {
  product,
  vendor,
}

@freezed
class FavoriteModel with _$FavoriteModel {
  const factory FavoriteModel({
    required String id,
    required String userId,
    required String itemId, // Product ID or Vendor ID
    required FavoriteType type,
    DateTime? createdAt,
  }) = _FavoriteModel;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteModelFromJson(_convertTimestamps(json));

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
