import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_model.freezed.dart';
part 'address_model.g.dart';

@freezed
class AddressModel with _$AddressModel {
  const factory AddressModel({
    String? id,
    required String userId,
    required String street,
    required String suburb,
    required String city,
    String? province,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? additionalInfo,
    @Default(false) bool isDefault,
    DateTime? createdAt,
  }) = _AddressModel;

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(_convertTimestamps(json));

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

extension AddressModelX on AddressModel {
  /// Returns formatted address as a single line
  String get formattedAddress {
    final parts = <String>[
      street,
      suburb,
      city,
      if (province != null) province!,
      if (country != null) country!,
    ];
    return parts.join(', ');
  }

  /// Returns short address (street and suburb only)
  String get shortAddress => '$street, $suburb';
}
