import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';

/// Service to handle push notifications for vendors
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<List<OrderModel>>? _orderSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  Set<String> _knownOrderIds = {};
  bool _isInitialized = false;

  /// Initialize notification service and request permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token for future use (server-side notifications)
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages - store subscription for disposal
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps - store subscription for disposal
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    }

    _isInitialized = true;
  }

  /// Start listening for new orders for a vendor
  void listenForNewOrders({
    required String vendorId,
    required Ref ref,
    required void Function(OrderModel order) onNewOrder,
  }) {
    _orderSubscription?.cancel();

    final ordersStream = ref.read(streamOrdersByVendorIdProvider(vendorId).future);

    // Get initial orders first
    ordersStream.then((initialOrders) {
      _knownOrderIds = initialOrders.map((o) => o.id).toSet();

      // Now listen for changes
      ref.listen(streamOrdersByVendorIdProvider(vendorId), (previous, next) {
        next.whenData((orders) {
          for (final order in orders) {
            if (!_knownOrderIds.contains(order.id)) {
              _knownOrderIds.add(order.id);
              if (order.status == 'pending') {
                onNewOrder(order);
              }
            }
          }
        });
      });
    });
  }

  /// Stop listening for orders
  void stopListening() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _knownOrderIds.clear();
  }

  /// Dispose all subscriptions - call when service is no longer needed
  void dispose() {
    _orderSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _orderSubscription = null;
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription = null;
    _knownOrderIds.clear();
    _isInitialized = false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Message tapped: ${message.data}');
    // Navigate to order details if orderId is present
  }

  /// Get the FCM token for this device
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

/// Provider for notification service with proper disposal
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider to track new order notifications
final newOrderNotifierProvider = StateProvider<OrderModel?>((ref) => null);
