import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mbare_core/src/models/cart_item_model.dart';
import 'package:mbare_core/src/models/address_model.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const OrderModel._();

  const factory OrderModel({
    required String id,
    required String customerId,
    required String vendorId,
    @JsonKey(
      toJson: _itemsToJson,
      fromJson: _itemsFromJson,
    )
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    @Default(0.0) double platformFee,
    required double total,
    required String status,
    @JsonKey(
      toJson: _addressToJson,
      fromJson: _addressFromJson,
    )
    required AddressModel deliveryAddress,
    String? driverId,
    String? paymentId,
    String? paymentMethod,
    String? paymentStatus,
    String? customerNotes,
    String? vendorNotes,
    String? driverNotes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? preparingAt,
    DateTime? readyAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    Map<String, dynamic>? metadata,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(_convertTimestamps(json));

  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    // Handle Firestore Timestamp conversion for all DateTime fields
    final dateFields = [
      'createdAt',
      'confirmedAt',
      'preparingAt',
      'readyAt',
      'pickedUpAt',
      'deliveredAt',
      'cancelledAt',
    ];

    for (final field in dateFields) {
      if (converted[field] is Timestamp) {
        converted[field] =
            (converted[field] as Timestamp).toDate().toIso8601String();
      }
    }

    return converted;
  }

  /// Returns formatted total
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  /// Returns formatted subtotal
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  /// Returns formatted delivery fee
  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';

  /// Returns formatted platform fee
  String get formattedPlatformFee => '\$${platformFee.toStringAsFixed(2)}';

  /// Returns vendor payout (subtotal - platform fee)
  double get vendorPayout => subtotal - platformFee;

  /// Returns formatted vendor payout
  String get formattedVendorPayout => '\$${vendorPayout.toStringAsFixed(2)}';

  /// Returns total quantity of items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order is pending
  bool get isPending => status == 'pending';

  /// Check if order is confirmed
  bool get isConfirmed => status == 'confirmed';

  /// Check if order is being prepared
  bool get isPreparing => status == 'preparing';

  /// Check if order is ready for pickup
  bool get isReady => status == 'ready';

  /// Check if order has been picked up
  bool get isPickedUp => status == 'picked_up';

  /// Check if order is in transit
  bool get isInTransit => status == 'in_transit';

  /// Check if order is out for delivery
  bool get isOutForDelivery => status == 'out_for_delivery';

  /// Check if order has been delivered
  bool get isDelivered => status == 'delivered';

  /// Check if order has been cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if order can be cancelled
  bool get canBeCancelled => isPending || isConfirmed;

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get payment status display
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'processing':
        return 'Processing Payment';
      case 'completed':
        return 'Payment Successful';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus ?? 'Unknown';
    }
  }
}

/// Convert items list to JSON
List<Map<String, dynamic>> _itemsToJson(List<CartItemModel> items) {
  return items.map((item) => item.toJson()).toList();
}

/// Convert items list from JSON
List<CartItemModel> _itemsFromJson(List<dynamic> json) {
  return json.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)).toList();
}

/// Convert address to JSON
Map<String, dynamic> _addressToJson(AddressModel address) {
  return address.toJson();
}

/// Convert address from JSON
AddressModel _addressFromJson(Map<String, dynamic> json) {
  return AddressModel.fromJson(json);
}
