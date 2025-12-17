import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String role, // customer, vendor, driver, admin
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(true) bool isActive,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isPhoneVerified,
    Map<String, dynamic>? metadata,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Extension methods for UserModel
extension UserModelX on UserModel {
  bool get isCustomer => role == 'customer';
  bool get isVendor => role == 'vendor';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';

  String get displayNameOrEmail => displayName ?? email;
}
