import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_method_repository.g.dart';

@riverpod
PaymentMethodRepository paymentMethodRepository(
  PaymentMethodRepositoryRef ref,
) {
  return PaymentMethodRepository(FirebaseFirestore.instance);
}

/// Stream all payment methods for a user
@riverpod
Stream<List<PaymentMethodModel>> userPaymentMethods(
  UserPaymentMethodsRef ref,
  String userId,
) {
  return ref
      .watch(paymentMethodRepositoryProvider)
      .streamUserPaymentMethods(userId);
}

/// Get default payment method for a user
@riverpod
Stream<PaymentMethodModel?> defaultPaymentMethod(
  DefaultPaymentMethodRef ref,
  String userId,
) {
  return ref
      .watch(paymentMethodRepositoryProvider)
      .streamDefaultPaymentMethod(userId);
}

class PaymentMethodRepository {
  final FirebaseFirestore _firestore;

  PaymentMethodRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _paymentMethodsCollection =>
      _firestore.collection('payment_methods');

  /// Add new payment method
  Future<Either<Failure, PaymentMethodModel>> addPaymentMethod(
    PaymentMethodModel paymentMethod,
  ) async {
    try {
      final paymentMethodRef = _paymentMethodsCollection.doc();
      final newPaymentMethod = paymentMethod.copyWith(
        id: paymentMethodRef.id,
        createdAt: DateTime.now(),
      );

      // If this is set as default, unset other defaults
      if (newPaymentMethod.isDefault) {
        await _unsetOtherDefaults(
          newPaymentMethod.userId,
          paymentMethodRef.id,
        );
      }

      await paymentMethodRef.set(newPaymentMethod.toJson());
      return right(newPaymentMethod);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to add payment method'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Update existing payment method
  Future<Either<Failure, void>> updatePaymentMethod(
    PaymentMethodModel paymentMethod,
  ) async {
    try {
      if (paymentMethod.id == null) {
        return left(
          const ValidationFailure(message: 'Payment method ID is required'),
        );
      }

      // If this is set as default, unset other defaults
      if (paymentMethod.isDefault) {
        await _unsetOtherDefaults(paymentMethod.userId, paymentMethod.id!);
      }

      await _paymentMethodsCollection
          .doc(paymentMethod.id)
          .update(paymentMethod.toJson());
      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: e.message ?? 'Failed to update payment method',
        ),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Delete payment method
  Future<Either<Failure, void>> deletePaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      await _paymentMethodsCollection.doc(paymentMethodId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: e.message ?? 'Failed to delete payment method',
        ),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Set payment method as default
  Future<Either<Failure, void>> setAsDefault(
    String userId,
    String paymentMethodId,
  ) async {
    try {
      // Unset all other defaults
      await _unsetOtherDefaults(userId, paymentMethodId);

      // Set this payment method as default
      await _paymentMethodsCollection
          .doc(paymentMethodId)
          .update({'isDefault': true});

      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: e.message ?? 'Failed to set default payment method',
        ),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Unset other default payment methods for user
  Future<void> _unsetOtherDefaults(String userId, String exceptId) async {
    final querySnapshot = await _paymentMethodsCollection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      if (doc.id != exceptId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }

  /// Stream all payment methods for a user
  Stream<List<PaymentMethodModel>> streamUserPaymentMethods(String userId) {
    return _paymentMethodsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final paymentMethods = snapshot.docs
          .map((doc) => PaymentMethodModel.fromJson(doc.data()))
          .toList();

      // Sort: default first, then by created date
      paymentMethods.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return paymentMethods;
    });
  }

  /// Stream default payment method for a user
  Stream<PaymentMethodModel?> streamDefaultPaymentMethod(String userId) {
    return _paymentMethodsCollection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return PaymentMethodModel.fromJson(snapshot.docs.first.data());
    });
  }

  /// Get all payment methods for a user (one-time fetch)
  Future<Either<Failure, List<PaymentMethodModel>>> getUserPaymentMethods(
    String userId,
  ) async {
    try {
      final querySnapshot = await _paymentMethodsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final paymentMethods = querySnapshot.docs
          .map((doc) => PaymentMethodModel.fromJson(doc.data()))
          .toList();

      // Sort: default first, then by created date
      paymentMethods.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return right(paymentMethods);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to get payment methods'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }
}
