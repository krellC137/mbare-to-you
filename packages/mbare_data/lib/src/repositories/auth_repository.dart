import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// Repository for authentication operations
class AuthRepository {
  AuthRepository({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  }) : _authService = authService,
       _firestoreService = firestoreService;

  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  /// Get current Firebase user
  User? get currentUser => _authService.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Sign in with email and password
  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.fold((Failure failure) => Left(failure), (User user) async {
      // Fetch user data from Firestore
      final userDataResult = await _firestoreService.getDocument(
        'users/${user.uid}',
      );

      return userDataResult.fold((Failure failure) => Left(failure), (
        Map<String, dynamic>? data,
      ) {
        if (data == null) {
          return const Left(NotFoundFailure(message: 'User data not found'));
        }
        return Right(UserModel.fromJson(data));
      });
    });
  }

  /// Register new user with email and password
  Future<Result<UserModel>> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    // Create auth user
    final authResult = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return authResult.fold((Failure failure) => Left(failure), (
      User user,
    ) async {
      // Create user model - set isActive to false for roles requiring approval
      final requiresApproval = role == 'driver' || role == 'vendor';
      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        isActive: !requiresApproval, // false for driver/vendor, true for customer
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final saveResult = await _firestoreService.setDocument(
        'users/${user.uid}',
        userModel.toJson(),
      );

      return saveResult.fold((Failure failure) => Left(failure), (_) async {
        // Update display name in Firebase Auth
        await _authService.updateProfile(displayName: displayName);

        // Send email verification
        await _authService.sendEmailVerification();

        // Create role-specific profile if additional data provided
        if (additionalData != null && role == 'driver') {
          await _firestoreService.setDocument(
            'driver_profiles/${user.uid}',
            {
              'id': user.uid,
              'userId': user.uid,
              ...additionalData,
              'isApproved': false,
              'isActive': false,
              'isAvailable': false,
              'rating': 0.0,
              'totalDeliveries': 0,
              'totalReviews': 0,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }

        // Create vendor profile if additional data provided
        if (additionalData != null && role == 'vendor') {
          await _firestoreService.setDocument(
            'vendors/${user.uid}',
            {
              'id': user.uid,
              'ownerId': user.uid,
              ...additionalData,
              'email': email,
              'phoneNumber': phoneNumber,
              'isApproved': false,
              'isActive': false,
              'rating': 0.0,
              'totalOrders': 0,
              'totalProducts': 0,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }

        return Right<Failure, UserModel>(userModel);
      });
    });
  }

  /// Sign out current user
  Future<Result<void>> signOut() async {
    return _authService.signOut();
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return _authService.sendPasswordResetEmail(email: email);
  }

  /// Send email verification
  Future<Result<void>> sendEmailVerification() async {
    return _authService.sendEmailVerification();
  }

  /// Reload current user to get updated email verification status
  Future<Result<void>> reloadUser() async {
    return _authService.reloadUser();
  }

  /// Update user password
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Reauthenticate first
    if (currentUser?.email == null) {
      return const Left(AuthFailure(message: 'No authenticated user found'));
    }

    final reauthResult = await _authService.reauthenticateWithEmailAndPassword(
      email: currentUser!.email!,
      password: currentPassword,
    );

    return reauthResult.fold(
      (Failure failure) => Left(failure),
      (_) => _authService.updatePassword(newPassword: newPassword),
    );
  }

  /// Update user email
  Future<Result<void>> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    // Reauthenticate first
    if (currentUser?.email == null) {
      return const Left(AuthFailure(message: 'No authenticated user found'));
    }

    final reauthResult = await _authService.reauthenticateWithEmailAndPassword(
      email: currentUser!.email!,
      password: password,
    );

    return reauthResult.fold((Failure failure) => Left(failure), (_) async {
      final updateResult = await _authService.updateEmail(newEmail: newEmail);

      return updateResult.fold((Failure failure) => Left(failure), (_) async {
        // Update email in Firestore
        await _firestoreService.updateDocument('users/${currentUser!.uid}', {
          'email': newEmail,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return const Right<Failure, void>(null);
      });
    });
  }

  /// Delete user account
  Future<Result<void>> deleteAccount(String password) async {
    if (currentUser?.email == null || currentUser?.uid == null) {
      return const Left(AuthFailure(message: 'No authenticated user found'));
    }

    // Reauthenticate first
    final reauthResult = await _authService.reauthenticateWithEmailAndPassword(
      email: currentUser!.email!,
      password: password,
    );

    return reauthResult.fold((Failure failure) => Left(failure), (_) async {
      final userId = currentUser!.uid;

      // Delete user data from Firestore
      await _firestoreService.deleteDocument('users/$userId');

      // Delete auth account
      return _authService.deleteAccount();
    });
  }

  /// Get current user data from Firestore
  Future<Result<UserModel>> getCurrentUserData() async {
    if (currentUser == null) {
      return const Left(AuthFailure(message: 'No authenticated user'));
    }

    final result = await _firestoreService.getDocument(
      'users/${currentUser!.uid}',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'User data not found'));
      }
      return Right(UserModel.fromJson(data));
    });
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Check if user email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
}

/// Provider for FirebaseAuthService
@Riverpod(keepAlive: true)
FirebaseAuthService firebaseAuthService(FirebaseAuthServiceRef ref) {
  return FirebaseAuthService(FirebaseAuth.instance);
}

/// Provider for FirestoreService
@Riverpod(keepAlive: true)
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService(FirebaseFirestore.instance);
}

/// Provider for AuthRepository
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    authService: ref.watch(firebaseAuthServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
}

/// Provider for current Firebase user stream
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
}

/// Provider for current user data
@riverpod
Future<UserModel?> currentUser(CurrentUserRef ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = authRepository.currentUser;

  if (user == null) {
    return null;
  }

  final result = await authRepository.getCurrentUserData();
  return result.fold((Failure _) => null, (UserModel userData) => userData);
}
