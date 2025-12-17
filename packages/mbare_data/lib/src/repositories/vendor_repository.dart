import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/src/repositories/auth_repository.dart';
import 'package:mbare_data/src/repositories/user_repository.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vendor_repository.g.dart';

/// Repository for vendor operations
class VendorRepository {
  VendorRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService;

  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static const String _collectionPath = 'vendors';

  /// Create new vendor
  Future<Result<String>> createVendor(VendorModel vendor) async {
    return _firestoreService.addDocument(_collectionPath, vendor.toJson());
  }

  /// Get vendor by ID
  Future<Result<VendorModel>> getVendorById(String vendorId) async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$vendorId',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'Vendor not found'));
      }
      return Right(VendorModel.fromJson(data));
    });
  }

  /// Stream vendor by ID
  Stream<Result<VendorModel?>> streamVendorById(String vendorId) {
    return _firestoreService.streamDocument('$_collectionPath/$vendorId').map((
      Result<Map<String, dynamic>?> result,
    ) {
      return result.fold((Failure failure) => Left(failure), (
        Map<String, dynamic>? data,
      ) {
        if (data == null) {
          return const Right(null);
        }
        return Right(VendorModel.fromJson(data));
      });
    });
  }

  /// Update vendor
  Future<Result<void>> updateVendor(
    String vendorId,
    Map<String, dynamic> data,
  ) async {
    // Add updatedAt timestamp
    final updateData = {...data, 'updatedAt': DateTime.now().toIso8601String()};

    return _firestoreService.updateDocument(
      '$_collectionPath/$vendorId',
      updateData,
    );
  }

  /// Upload vendor logo
  Future<Result<String>> uploadVendorLogo({
    required String vendorId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    return _storageService.uploadVendorLogo(
      vendorId: vendorId,
      file: file,
      onProgress: onProgress,
    );
  }

  /// Delete vendor logo
  Future<Result<void>> deleteVendorLogo(String logoUrl) async {
    return _storageService.deleteFileByUrl(logoUrl);
  }

  /// Get all vendors
  Future<Result<List<VendorModel>>> getAllVendors({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Get approved vendors
  Future<Result<List<VendorModel>>> getApprovedVendors({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true)
              .orderBy('businessName'),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Stream approved vendors
  Stream<Result<List<VendorModel>>> streamApprovedVendors({int? limit}) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder:
              (query) => query
                  .where('isApproved', isEqualTo: true)
                  .where('isActive', isEqualTo: true),
          // Note: orderBy('businessName') removed to avoid composite index requirement
          // Vendors will be sorted in-memory instead
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final vendors =
                docs
                    .map(
                      (Map<String, dynamic> doc) => VendorModel.fromJson(doc),
                    )
                    .toList();
            // Sort vendors by business name in-memory
            vendors.sort((a, b) => a.businessName.compareTo(b.businessName));
            return Right(vendors);
          });
        });
  }

  /// Get pending vendors (awaiting approval)
  Future<Result<List<VendorModel>>> getPendingVendors({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('isApproved', isEqualTo: false)
              .orderBy('createdAt', descending: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Get vendors by market section
  Future<Result<List<VendorModel>>> getVendorsByMarketSection(
    String marketSection, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('marketSection', isEqualTo: marketSection)
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Get vendors by category
  Future<Result<List<VendorModel>>> getVendorsByCategory(
    String category, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('categories', arrayContains: category)
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Get vendors by owner ID
  Future<Result<List<VendorModel>>> getVendorsByOwnerId(
    String ownerId, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query.where('ownerId', isEqualTo: ownerId),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Stream vendors by owner ID
  Stream<Result<List<VendorModel>>> streamVendorsByOwnerId(
    String ownerId, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder: (query) => query.where('ownerId', isEqualTo: ownerId),
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final vendors =
                docs
                    .map(
                      (Map<String, dynamic> doc) => VendorModel.fromJson(doc),
                    )
                    .toList();
            return Right(vendors);
          });
        });
  }

  /// Search vendors by name
  Future<Result<List<VendorModel>>> searchVendorsByName(
    String name, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('businessName', isGreaterThanOrEqualTo: name)
              .where('businessName', isLessThanOrEqualTo: '$name\uf8ff')
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final vendors =
          docs
              .map((Map<String, dynamic> doc) => VendorModel.fromJson(doc))
              .toList();
      return Right(vendors);
    });
  }

  /// Approve vendor
  Future<Result<void>> approveVendor(String vendorId) async {
    return updateVendor(vendorId, {'isApproved': true});
  }

  /// Reject vendor
  Future<Result<void>> rejectVendor(String vendorId) async {
    return updateVendor(vendorId, {'isApproved': false});
  }

  /// Activate vendor
  Future<Result<void>> activateVendor(String vendorId) async {
    return updateVendor(vendorId, {'isActive': true});
  }

  /// Deactivate vendor
  Future<Result<void>> deactivateVendor(String vendorId) async {
    return updateVendor(vendorId, {'isActive': false});
  }

  /// Update vendor rating
  Future<Result<void>> updateVendorRating(
    String vendorId,
    double rating,
    int reviewCount,
  ) async {
    return updateVendor(vendorId, {
      'rating': rating,
      'reviewCount': reviewCount,
    });
  }

  /// Delete vendor
  Future<Result<void>> deleteVendor(String vendorId) async {
    return _firestoreService.deleteDocument('$_collectionPath/$vendorId');
  }
}

/// Provider for VendorRepository
@Riverpod(keepAlive: true)
VendorRepository vendorRepository(VendorRepositoryRef ref) {
  final storageService = ref.watch(storageServiceProvider);
  return VendorRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: storageService,
  );
}

/// Provider for a specific vendor by ID
@riverpod
Future<VendorModel?> vendorById(VendorByIdRef ref, String vendorId) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final result = await vendorRepository.getVendorById(vendorId);

  return result.fold((Failure _) => null, (VendorModel vendor) => vendor);
}

/// Provider to stream a vendor by ID
@riverpod
Stream<VendorModel?> streamVendorById(
  StreamVendorByIdRef ref,
  String vendorId,
) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return vendorRepository
      .streamVendorById(vendorId)
      .map(
        (Result<VendorModel?> result) =>
            result.fold((Failure _) => null, (VendorModel? vendor) => vendor),
      );
}

/// Provider for approved vendors
@riverpod
Future<List<VendorModel>> approvedVendors(
  ApprovedVendorsRef ref, {
  int? limit,
}) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final result = await vendorRepository.getApprovedVendors(limit: limit);

  return result.fold(
    (Failure _) => <VendorModel>[],
    (List<VendorModel> vendors) => vendors,
  );
}

/// Provider to stream approved vendors
@riverpod
Stream<List<VendorModel>> streamApprovedVendors(
  StreamApprovedVendorsRef ref, {
  int? limit,
}) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return vendorRepository
      .streamApprovedVendors(limit: limit)
      .map(
        (Result<List<VendorModel>> result) => result.fold(
          (Failure _) => <VendorModel>[],
          (List<VendorModel> vendors) => vendors,
        ),
      );
}

/// Provider for vendors by owner ID
@riverpod
Future<List<VendorModel>> vendorsByOwnerId(
  VendorsByOwnerIdRef ref,
  String ownerId, {
  int? limit,
}) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final result = await vendorRepository.getVendorsByOwnerId(
    ownerId,
    limit: limit,
  );

  return result.fold(
    (Failure _) => <VendorModel>[],
    (List<VendorModel> vendors) => vendors,
  );
}

/// Provider to stream all vendors (admin)
@riverpod
Stream<List<VendorModel>> streamAllVendors(StreamAllVendorsRef ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .streamCollection('vendors')
      .map((Result<List<Map<String, dynamic>>> result) {
        return result.fold(
          (Failure _) => <VendorModel>[],
          (List<Map<String, dynamic>> docs) {
            return docs.map((doc) => VendorModel.fromJson(doc)).toList();
          },
        );
      });
}
