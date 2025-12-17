import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/src/repositories/auth_repository.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driver_profile_repository.g.dart';

/// Repository for driver profile operations
class DriverProfileRepository {
  DriverProfileRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  static const String _collectionPath = 'driver_profiles';

  /// Create new driver profile
  Future<Result<String>> createDriverProfile(DriverProfileModel profile) async {
    final result = await _firestoreService.setDocument(
      '$_collectionPath/${profile.id}',
      profile.toJson(),
    );
    return result.fold(
      (failure) => Left(failure),
      (_) => Right(profile.id),
    );
  }

  /// Get driver profile by ID
  Future<Result<DriverProfileModel>> getDriverProfileById(String profileId) async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$profileId',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'Driver profile not found'));
      }
      return Right(DriverProfileModel.fromJson(data));
    });
  }

  /// Get driver profile by user ID
  Future<Result<DriverProfileModel>> getDriverProfileByUserId(String userId) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
      limit: 1,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      if (docs.isEmpty) {
        return const Left(NotFoundFailure(message: 'Driver profile not found'));
      }
      return Right(DriverProfileModel.fromJson(docs.first));
    });
  }

  /// Stream driver profile by user ID
  Stream<Result<DriverProfileModel?>> streamDriverProfileByUserId(String userId) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder: (query) => query.where('userId', isEqualTo: userId),
          limit: 1,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            if (docs.isEmpty) {
              return const Right(null);
            }
            return Right(DriverProfileModel.fromJson(docs.first));
          });
        });
  }

  /// Update driver profile
  Future<Result<void>> updateDriverProfile(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    final updateData = {...data, 'updatedAt': DateTime.now().toIso8601String()};

    return _firestoreService.updateDocument(
      '$_collectionPath/$profileId',
      updateData,
    );
  }

  /// Get all driver profiles
  Future<Result<List<DriverProfileModel>>> getAllDriverProfiles({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final profiles = docs
          .map((Map<String, dynamic> doc) => DriverProfileModel.fromJson(doc))
          .toList();
      return Right(profiles);
    });
  }

  /// Stream all driver profiles
  Stream<Result<List<DriverProfileModel>>> streamAllDriverProfiles({int? limit}) {
    return _firestoreService
        .streamCollection(_collectionPath, limit: limit)
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final profiles = docs
                .map((Map<String, dynamic> doc) => DriverProfileModel.fromJson(doc))
                .toList();
            return Right(profiles);
          });
        });
  }

  /// Get approved drivers
  Future<Result<List<DriverProfileModel>>> getApprovedDrivers({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final profiles = docs
          .map((Map<String, dynamic> doc) => DriverProfileModel.fromJson(doc))
          .toList();
      return Right(profiles);
    });
  }

  /// Get available drivers (can accept deliveries)
  Future<Result<List<DriverProfileModel>>> getAvailableDrivers({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final profiles = docs
          .map((Map<String, dynamic> doc) => DriverProfileModel.fromJson(doc))
          .toList();
      return Right(profiles);
    });
  }

  /// Approve driver
  Future<Result<void>> approveDriver(String profileId) async {
    return updateDriverProfile(profileId, {'isApproved': true});
  }

  /// Reject driver
  Future<Result<void>> rejectDriver(String profileId) async {
    return updateDriverProfile(profileId, {'isApproved': false});
  }

  /// Set driver availability
  Future<Result<void>> setDriverAvailability(String profileId, {required bool isAvailable}) async {
    return updateDriverProfile(profileId, {'isAvailable': isAvailable});
  }

  /// Update driver rating
  Future<Result<void>> updateDriverRating(
    String profileId,
    double rating,
    int reviewCount,
  ) async {
    return updateDriverProfile(profileId, {
      'rating': rating,
      'totalReviews': reviewCount,
    });
  }

  /// Delete driver profile
  Future<Result<void>> deleteDriverProfile(String profileId) async {
    return _firestoreService.deleteDocument('$_collectionPath/$profileId');
  }
}

/// Provider for DriverProfileRepository
@Riverpod(keepAlive: true)
DriverProfileRepository driverProfileRepository(DriverProfileRepositoryRef ref) {
  return DriverProfileRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
}

/// Provider for a driver profile by user ID
@riverpod
Future<DriverProfileModel?> driverProfileByUserId(
  DriverProfileByUserIdRef ref,
  String userId,
) async {
  final repository = ref.watch(driverProfileRepositoryProvider);
  final result = await repository.getDriverProfileByUserId(userId);

  return result.fold((Failure _) => null, (DriverProfileModel profile) => profile);
}

/// Provider to stream driver profile by user ID
@riverpod
Stream<DriverProfileModel?> streamDriverProfileByUserId(
  StreamDriverProfileByUserIdRef ref,
  String userId,
) {
  final repository = ref.watch(driverProfileRepositoryProvider);
  return repository
      .streamDriverProfileByUserId(userId)
      .map(
        (Result<DriverProfileModel?> result) =>
            result.fold((Failure _) => null, (DriverProfileModel? profile) => profile),
      );
}

/// Provider to stream all driver profiles
@riverpod
Stream<List<DriverProfileModel>> streamAllDriverProfiles(
  StreamAllDriverProfilesRef ref, {
  int? limit,
}) {
  final repository = ref.watch(driverProfileRepositoryProvider);
  return repository
      .streamAllDriverProfiles(limit: limit)
      .map(
        (Result<List<DriverProfileModel>> result) => result.fold(
          (Failure _) => <DriverProfileModel>[],
          (List<DriverProfileModel> profiles) => profiles,
        ),
      );
}

/// Provider for available drivers
@riverpod
Future<List<DriverProfileModel>> availableDrivers(
  AvailableDriversRef ref, {
  int? limit,
}) async {
  final repository = ref.watch(driverProfileRepositoryProvider);
  final result = await repository.getAvailableDrivers(limit: limit);

  return result.fold(
    (Failure _) => <DriverProfileModel>[],
    (List<DriverProfileModel> profiles) => profiles,
  );
}
