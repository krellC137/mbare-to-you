import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/src/repositories/auth_repository.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_repository.g.dart';

/// Repository for order operations
class OrderRepository {
  OrderRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  static const String _collectionPath = 'orders';

  /// Create new order
  Future<Result<String>> createOrder(OrderModel order) async {
    // Generate a new document reference to get the ID
    final docRef = _firestoreService.firestore.collection(_collectionPath).doc();
    final orderId = docRef.id;

    // Create order with the generated ID
    final orderWithId = order.copyWith(id: orderId);

    // Save the order with its ID included in the document
    final result = await _firestoreService.setDocument(
      '$_collectionPath/$orderId',
      orderWithId.toJson(),
    );

    return result.fold(
      (failure) => Left(failure),
      (_) => Right(orderId),
    );
  }

  /// Get order by ID
  Future<Result<OrderModel>> getOrderById(String orderId) async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$orderId',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'Order not found'));
      }
      return Right(OrderModel.fromJson(data));
    });
  }

  /// Stream order by ID
  Stream<Result<OrderModel?>> streamOrderById(String orderId) {
    return _firestoreService.streamDocument('$_collectionPath/$orderId').map((
      Result<Map<String, dynamic>?> result,
    ) {
      return result.fold((Failure failure) => Left(failure), (
        Map<String, dynamic>? data,
      ) {
        if (data == null) {
          return const Right(null);
        }
        return Right(OrderModel.fromJson(data));
      });
    });
  }

  /// Update order
  Future<Result<void>> updateOrder(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    // Add updatedAt timestamp
    final updateData = {...data, 'updatedAt': DateTime.now().toIso8601String()};

    return _firestoreService.updateDocument(
      '$_collectionPath/$orderId',
      updateData,
    );
  }

  /// Get orders by customer ID
  Future<Result<List<OrderModel>>> getOrdersByCustomerId(
    String customerId, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('customerId', isEqualTo: customerId)
              .orderBy('createdAt', descending: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final orders =
          docs
              .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
              .toList();
      return Right(orders);
    });
  }

  /// Stream orders by customer ID
  Stream<Result<List<OrderModel>>> streamOrdersByCustomerId(
    String customerId, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder:
              (query) => query.where('customerId', isEqualTo: customerId),
          // Note: orderBy removed to avoid composite index requirement
          // Orders will be sorted in-memory instead
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold(
            (Failure failure) => Left(failure),
            (List<Map<String, dynamic>> docs) {
              final orders =
                  docs
                      .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
                      .toList();
              // Sort orders by creation date in-memory (newest first)
              orders.sort((a, b) {
                if (a.createdAt == null && b.createdAt == null) return 0;
                if (a.createdAt == null) return 1;
                if (b.createdAt == null) return -1;
                return b.createdAt!.compareTo(a.createdAt!);
              });
              return Right(orders);
            },
          );
        });
  }

  /// Get orders by vendor ID
  Future<Result<List<OrderModel>>> getOrdersByVendorId(
    String vendorId, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('vendorId', isEqualTo: vendorId)
              .orderBy('createdAt', descending: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final orders =
          docs
              .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
              .toList();
      return Right(orders);
    });
  }

  /// Stream orders by vendor ID
  Stream<Result<List<OrderModel>>> streamOrdersByVendorId(
    String vendorId, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder:
              (query) => query.where('vendorId', isEqualTo: vendorId),
          // Note: orderBy removed to avoid composite index requirement
          // Orders will be sorted in-memory instead
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final orders =
                docs
                    .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
                    .toList();
            // Sort orders by creation date in-memory (newest first)
            orders.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            return Right(orders);
          });
        });
  }

  /// Get orders by status
  Future<Result<List<OrderModel>>> getOrdersByStatus(
    String status, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('status', isEqualTo: status)
              .orderBy('createdAt', descending: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final orders =
          docs
              .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
              .toList();
      return Right(orders);
    });
  }

  /// Stream orders by status
  Stream<Result<List<OrderModel>>> streamOrdersByStatus(
    String status, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder:
              (query) => query.where('status', isEqualTo: status),
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final orders =
                docs
                    .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
                    .toList();
            // Sort orders by creation date in-memory (newest first)
            orders.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            return Right(orders);
          });
        });
  }

  /// Get orders by driver ID
  Future<Result<List<OrderModel>>> getOrdersByDriverId(
    String driverId, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('driverId', isEqualTo: driverId)
              .orderBy('createdAt', descending: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final orders =
          docs
              .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
              .toList();
      return Right(orders);
    });
  }

  /// Stream orders by driver ID
  Stream<Result<List<OrderModel>>> streamOrdersByDriverId(
    String driverId, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder:
              (query) => query.where('driverId', isEqualTo: driverId),
          // Note: orderBy removed to avoid composite index requirement
          // Orders will be sorted in-memory instead
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final orders =
                docs
                    .map((Map<String, dynamic> doc) => OrderModel.fromJson(doc))
                    .toList();
            // Sort orders by creation date in-memory (newest first)
            orders.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            return Right(orders);
          });
        });
  }

  /// Update order status with automatic timestamp tracking
  Future<Result<void>> updateOrderStatus(String orderId, String status) async {
    final updateData = <String, dynamic>{'status': status};

    // Set appropriate timestamp based on status
    final now = DateTime.now().toIso8601String();
    switch (status) {
      case 'confirmed':
        updateData['confirmedAt'] = now;
        break;
      case 'preparing':
        updateData['preparingAt'] = now;
        break;
      case 'ready':
        updateData['readyAt'] = now;
        break;
      case 'picked_up':
      case 'out_for_delivery':
        updateData['pickedUpAt'] = now;
        break;
      case 'delivered':
        updateData['deliveredAt'] = now;
        break;
      case 'cancelled':
        updateData['cancelledAt'] = now;
        break;
    }

    return updateOrder(orderId, updateData);
  }

  /// Assign driver to order
  Future<Result<void>> assignDriver(String orderId, String driverId) async {
    return updateOrder(orderId, {'driverId': driverId});
  }

  /// Accept delivery - atomic update that assigns driver and updates status
  Future<Result<void>> acceptDelivery(String orderId, String driverId) async {
    return updateOrder(orderId, {
      'driverId': driverId,
      'status': 'out_for_delivery',
      'pickedUpAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update payment status
  Future<Result<void>> updatePaymentStatus(
    String orderId,
    String paymentStatus,
  ) async {
    return updateOrder(orderId, {'paymentStatus': paymentStatus});
  }

  /// Cancel order
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    return updateOrder(orderId, {
      'status': 'cancelled',
      'cancellationReason': reason,
    });
  }

  /// Complete order
  Future<Result<void>> completeOrder(String orderId) async {
    return updateOrder(orderId, {
      'status': 'delivered',
      'deliveredAt': DateTime.now().toIso8601String(),
    });
  }

  /// Delete order
  Future<Result<void>> deleteOrder(String orderId) async {
    return _firestoreService.deleteDocument('$_collectionPath/$orderId');
  }

  /// Get active orders count for vendor
  Future<Result<int>> getActiveOrdersCountForVendor(String vendorId) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('vendorId', isEqualTo: vendorId)
              .where(
                'status',
                whereIn: [
                  'pending',
                  'confirmed',
                  'preparing',
                  'ready',
                  'out_for_delivery',
                ],
              ),
    );

    return result.fold(
      (Failure failure) => Left(failure),
      (List<Map<String, dynamic>> docs) => Right(docs.length),
    );
  }

  /// Get completed orders count for customer
  Future<Result<int>> getCompletedOrdersCountForCustomer(
    String customerId,
  ) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('customerId', isEqualTo: customerId)
              .where('status', isEqualTo: 'delivered'),
    );

    return result.fold(
      (Failure failure) => Left(failure),
      (List<Map<String, dynamic>> docs) => Right(docs.length),
    );
  }
}

/// Provider for OrderRepository
@Riverpod(keepAlive: true)
OrderRepository orderRepository(OrderRepositoryRef ref) {
  return OrderRepository(firestoreService: ref.watch(firestoreServiceProvider));
}

/// Provider for a specific order by ID
@riverpod
Future<OrderModel?> orderById(OrderByIdRef ref, String orderId) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final result = await orderRepository.getOrderById(orderId);

  return result.fold((Failure _) => null, (OrderModel order) => order);
}

/// Provider to stream an order by ID
@riverpod
Stream<OrderModel?> streamOrderById(StreamOrderByIdRef ref, String orderId) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository
      .streamOrderById(orderId)
      .map(
        (Result<OrderModel?> result) =>
            result.fold((Failure _) => null, (OrderModel? order) => order),
      );
}

/// Provider for orders by customer ID
@riverpod
Future<List<OrderModel>> ordersByCustomerId(
  OrdersByCustomerIdRef ref,
  String customerId, {
  int? limit,
}) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final result = await orderRepository.getOrdersByCustomerId(
    customerId,
    limit: limit,
  );

  return result.fold(
    (Failure _) => <OrderModel>[],
    (List<OrderModel> orders) => orders,
  );
}

/// Provider to stream orders by customer ID
@riverpod
Stream<List<OrderModel>> streamOrdersByCustomerId(
  StreamOrdersByCustomerIdRef ref,
  String customerId, {
  int? limit,
}) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository
      .streamOrdersByCustomerId(customerId, limit: limit)
      .map(
        (Result<List<OrderModel>> result) => result.fold(
          (Failure _) => <OrderModel>[],
          (List<OrderModel> orders) => orders,
        ),
      );
}

/// Provider for orders by vendor ID
@riverpod
Future<List<OrderModel>> ordersByVendorId(
  OrdersByVendorIdRef ref,
  String vendorId, {
  int? limit,
}) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final result = await orderRepository.getOrdersByVendorId(
    vendorId,
    limit: limit,
  );

  return result.fold(
    (Failure _) => <OrderModel>[],
    (List<OrderModel> orders) => orders,
  );
}

/// Provider to stream orders by vendor ID
@riverpod
Stream<List<OrderModel>> streamOrdersByVendorId(
  StreamOrdersByVendorIdRef ref,
  String vendorId, {
  int? limit,
}) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository
      .streamOrdersByVendorId(vendorId, limit: limit)
      .map(
        (Result<List<OrderModel>> result) => result.fold(
          (Failure _) => <OrderModel>[],
          (List<OrderModel> orders) => orders,
        ),
      );
}

/// Provider to stream orders by status (for drivers to see available orders)
@riverpod
Stream<List<OrderModel>> streamOrdersByStatus(
  StreamOrdersByStatusRef ref,
  String status, {
  int? limit,
}) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository
      .streamOrdersByStatus(status, limit: limit)
      .map(
        (Result<List<OrderModel>> result) => result.fold(
          (Failure _) => <OrderModel>[],
          (List<OrderModel> orders) => orders,
        ),
      );
}

/// Provider to stream orders by driver ID
@riverpod
Stream<List<OrderModel>> streamOrdersByDriverId(
  StreamOrdersByDriverIdRef ref,
  String driverId, {
  int? limit,
}) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository
      .streamOrdersByDriverId(driverId, limit: limit)
      .map(
        (Result<List<OrderModel>> result) => result.fold(
          (Failure _) => <OrderModel>[],
          (List<OrderModel> orders) => orders,
        ),
      );
}

/// Provider to stream all orders (admin)
@riverpod
Stream<List<OrderModel>> streamAllOrders(StreamAllOrdersRef ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .streamCollection('orders')
      .map((Result<List<Map<String, dynamic>>> result) {
        return result.fold(
          (Failure _) => <OrderModel>[],
          (List<Map<String, dynamic>> docs) {
            final orders = docs.map((doc) => OrderModel.fromJson(doc)).toList();
            orders.sort((a, b) {
              if (a.createdAt == null && b.createdAt == null) return 0;
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            return orders;
          },
        );
      });
}
