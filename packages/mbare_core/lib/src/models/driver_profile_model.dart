import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_profile_model.freezed.dart';
part 'driver_profile_model.g.dart';

@freezed
class DriverProfileModel with _$DriverProfileModel {
  const factory DriverProfileModel({
    required String id,
    required String userId, // Links to users table
    required String vehicleType, // motorcycle, bicycle, car
    String? vehiclePlateNumber,
    String? licenseNumber,
    String? photoUrl,
    @Default(false) bool isApproved,
    @Default(true) bool isActive,
    @Default(true) bool isAvailable, // Currently accepting deliveries
    @Default(0.0) double rating,
    @Default(0) int totalDeliveries,
    @Default(0) int totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(_convertTimestamps(json));

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

extension DriverProfileModelX on DriverProfileModel {
  /// Returns true if driver can accept deliveries
  bool get canAcceptDeliveries => isApproved && isActive && isAvailable;

  /// Returns rating display (e.g., "4.5")
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Returns vehicle display name
  String get vehicleDisplay {
    switch (vehicleType) {
      case 'motorcycle':
        return 'Motorcycle';
      case 'bicycle':
        return 'Bicycle';
      case 'car':
        return 'Car';
      default:
        return vehicleType;
    }
  }
}
