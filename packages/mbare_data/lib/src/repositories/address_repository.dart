import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_repository.g.dart';

@riverpod
AddressRepository addressRepository(AddressRepositoryRef ref) {
  return AddressRepository(FirebaseFirestore.instance);
}

/// Stream all addresses for a user
@riverpod
Stream<List<AddressModel>> userAddresses(
  UserAddressesRef ref,
  String userId,
) {
  return ref.watch(addressRepositoryProvider).streamUserAddresses(userId);
}

/// Get default address for a user
@riverpod
Stream<AddressModel?> defaultAddress(
  DefaultAddressRef ref,
  String userId,
) {
  return ref.watch(addressRepositoryProvider).streamDefaultAddress(userId);
}

class AddressRepository {
  final FirebaseFirestore _firestore;

  AddressRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _addressesCollection =>
      _firestore.collection('addresses');

  /// Add new address
  Future<Either<Failure, AddressModel>> addAddress(
    AddressModel address,
  ) async {
    try {
      final addressRef = _addressesCollection.doc();
      final newAddress = address.copyWith(
        id: addressRef.id,
        createdAt: DateTime.now(),
      );

      // If this is set as default, unset other defaults
      if (newAddress.isDefault) {
        await _unsetOtherDefaults(newAddress.userId, addressRef.id);
      }

      await addressRef.set(newAddress.toJson());
      return right(newAddress);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to add address'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Update existing address
  Future<Either<Failure, void>> updateAddress(AddressModel address) async {
    try {
      if (address.id == null) {
        return left(
          const ValidationFailure(message: 'Address ID is required'),
        );
      }

      // If this is set as default, unset other defaults
      if (address.isDefault) {
        await _unsetOtherDefaults(address.userId, address.id!);
      }

      await _addressesCollection.doc(address.id).update(address.toJson());
      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to update address'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Delete address
  Future<Either<Failure, void>> deleteAddress(String addressId) async {
    try {
      await _addressesCollection.doc(addressId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to delete address'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Set address as default
  Future<Either<Failure, void>> setAsDefault(
    String userId,
    String addressId,
  ) async {
    try {
      // Unset all other defaults
      await _unsetOtherDefaults(userId, addressId);

      // Set this address as default
      await _addressesCollection.doc(addressId).update({'isDefault': true});

      return right(null);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to set default address'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Unset other default addresses for user
  Future<void> _unsetOtherDefaults(String userId, String exceptId) async {
    final querySnapshot = await _addressesCollection
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

  /// Get address by ID
  Future<Either<Failure, AddressModel?>> getAddressById(
    String addressId,
  ) async {
    try {
      final doc = await _addressesCollection.doc(addressId).get();
      if (!doc.exists) {
        return right(null);
      }
      return right(AddressModel.fromJson(doc.data()!));
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to get address'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Stream all addresses for a user
  Stream<List<AddressModel>> streamUserAddresses(String userId) {
    return _addressesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final addresses = snapshot.docs
          .map((doc) => AddressModel.fromJson(doc.data()))
          .toList();

      // Sort: default first, then by created date
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return addresses;
    });
  }

  /// Stream default address for a user
  Stream<AddressModel?> streamDefaultAddress(String userId) {
    return _addressesCollection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AddressModel.fromJson(snapshot.docs.first.data());
    });
  }

  /// Get all addresses for a user (one-time fetch)
  Future<Either<Failure, List<AddressModel>>> getUserAddresses(
    String userId,
  ) async {
    try {
      final querySnapshot = await _addressesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final addresses = querySnapshot.docs
          .map((doc) => AddressModel.fromJson(doc.data()))
          .toList();

      // Sort: default first, then by created date
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return right(addresses);
    } on FirebaseException catch (e) {
      return left(
        ServerFailure(message: e.message ?? 'Failed to get addresses'),
      );
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }
}
