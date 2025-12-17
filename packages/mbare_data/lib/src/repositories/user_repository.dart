import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/src/repositories/auth_repository.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// Repository for user operations
class UserRepository {
  UserRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService;

  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static const String _collectionPath = 'users';

  /// Get user by ID
  Future<Result<UserModel>> getUserById(String userId) async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$userId',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'User not found'));
      }
      return Right(UserModel.fromJson(data));
    });
  }

  /// Stream user by ID
  Stream<Result<UserModel?>> streamUserById(String userId) {
    return _firestoreService.streamDocument('$_collectionPath/$userId').map((
      Result<Map<String, dynamic>?> result,
    ) {
      return result.fold((Failure failure) => Left(failure), (
        Map<String, dynamic>? data,
      ) {
        if (data == null) {
          return const Right(null);
        }
        return Right(UserModel.fromJson(data));
      });
    });
  }

  /// Update user profile
  Future<Result<void>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    // Add updatedAt timestamp
    final updateData = {...data, 'updatedAt': DateTime.now().toIso8601String()};

    return _firestoreService.updateDocument(
      '$_collectionPath/$userId',
      updateData,
    );
  }

  /// Update user display name
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    return updateUser(userId, {'displayName': displayName});
  }

  /// Update user phone number
  Future<Result<void>> updatePhoneNumber(
    String userId,
    String phoneNumber,
  ) async {
    return updateUser(userId, {'phoneNumber': phoneNumber});
  }

  /// Update user photo URL
  Future<Result<void>> updatePhotoUrl(String userId, String photoUrl) async {
    return updateUser(userId, {'photoUrl': photoUrl});
  }

  /// Upload user profile photo
  Future<Result<String>> uploadProfilePhoto({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    return _storageService.uploadUserPhoto(
      userId: userId,
      file: file,
      onProgress: onProgress,
    );
  }

  /// Delete user profile photo
  Future<Result<void>> deleteProfilePhoto(String photoUrl) async {
    return _storageService.deleteFileByUrl(photoUrl);
  }

  /// Deactivate user account
  Future<Result<void>> deactivateUser(String userId) async {
    return updateUser(userId, {'isActive': false});
  }

  /// Activate user account
  Future<Result<void>> activateUser(String userId) async {
    return updateUser(userId, {'isActive': true});
  }

  /// Get all users (admin only)
  Future<Result<List<UserModel>>> getAllUsers({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final users =
          docs
              .map((Map<String, dynamic> doc) => UserModel.fromJson(doc))
              .toList();
      return Right(users);
    });
  }

  /// Get users by role
  Future<Result<List<UserModel>>> getUsersByRole(
    String role, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query.where('role', isEqualTo: role),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final users =
          docs
              .map((Map<String, dynamic> doc) => UserModel.fromJson(doc))
              .toList();
      return Right(users);
    });
  }

  /// Stream users by role
  Stream<Result<List<UserModel>>> streamUsersByRole(String role, {int? limit}) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder: (query) => query.where('role', isEqualTo: role),
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final users =
                docs
                    .map((Map<String, dynamic> doc) => UserModel.fromJson(doc))
                    .toList();
            return Right(users);
          });
        });
  }

  /// Search users by display name
  Future<Result<List<UserModel>>> searchUsersByName(
    String name, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('displayName', isGreaterThanOrEqualTo: name)
              .where('displayName', isLessThanOrEqualTo: '$name\uf8ff'),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final users =
          docs
              .map((Map<String, dynamic> doc) => UserModel.fromJson(doc))
              .toList();
      return Right(users);
    });
  }

  /// Get active users count
  Future<Result<int>> getActiveUsersCount() async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query.where('isActive', isEqualTo: true),
    );

    return result.fold(
      (Failure failure) => Left(failure),
      (List<Map<String, dynamic>> docs) => Right(docs.length),
    );
  }
}

/// Provider for UserRepository
@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
}

/// Provider for StorageService
@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) {
  return StorageService(FirebaseStorage.instance);
}

/// Provider for a specific user by ID
@riverpod
Future<UserModel?> userById(UserByIdRef ref, String userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final result = await userRepository.getUserById(userId);

  return result.fold((Failure _) => null, (UserModel user) => user);
}

/// Provider to stream a user by ID
@riverpod
Stream<UserModel?> streamUserById(StreamUserByIdRef ref, String userId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository
      .streamUserById(userId)
      .map(
        (Result<UserModel?> result) =>
            result.fold((Failure _) => null, (UserModel? user) => user),
      );
}

/// Provider for users by role
@riverpod
Future<List<UserModel>> usersByRole(
  UsersByRoleRef ref,
  String role, {
  int? limit,
}) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final result = await userRepository.getUsersByRole(role, limit: limit);

  return result.fold(
    (Failure _) => <UserModel>[],
    (List<UserModel> users) => users,
  );
}

/// Provider to stream all users (admin)
@riverpod
Stream<List<UserModel>> streamAllUsers(StreamAllUsersRef ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .streamCollection('users')
      .map((Result<List<Map<String, dynamic>>> result) {
        return result.fold(
          (Failure _) => <UserModel>[],
          (List<Map<String, dynamic>> docs) {
            return docs.map((doc) => UserModel.fromJson(doc)).toList();
          },
        );
      });
}
