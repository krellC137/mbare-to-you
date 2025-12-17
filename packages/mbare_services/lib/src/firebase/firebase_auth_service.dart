import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbare_core/mbare_core.dart';

/// Firebase Authentication service wrapper
class FirebaseAuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user changes stream (includes token refresh)
  Stream<User?> get userChanges => _auth.userChanges();

  /// Sign in with email and password
  Future<Result<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return failure(
          const AuthFailure(message: 'Sign in failed - no user returned'),
        );
      }

      return success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Create user with email and password
  Future<Result<User>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return failure(
          const AuthFailure(message: 'Sign up failed - no user returned'),
        );
      }

      return success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return success(null);
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return success(null);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Send email verification
  Future<Result<void>> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.sendEmailVerification();
      return success(null);
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Reload current user
  Future<Result<void>> reloadUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.reload();
      return success(null);
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Update user profile (display name, photo URL)
  Future<Result<void>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();

      return success(null);
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Update email
  Future<Result<void>> updateEmail({required String newEmail}) async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.verifyBeforeUpdateEmail(newEmail);
      return success(null);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Update password
  Future<Result<void>> updatePassword({required String newPassword}) async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.updatePassword(newPassword);
      return success(null);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Delete user account
  Future<Result<void>> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      await user.delete();
      return success(null);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Reauthenticate with email and password
  Future<Result<void>> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return failure(const AuthFailure(message: 'No user signed in'));
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return success(null);
    } on FirebaseAuthException catch (e) {
      return failure(
        AuthFailure(message: _getAuthErrorMessage(e.code), code: e.code),
      );
    } catch (e) {
      return failure(AuthFailure(message: e.toString()));
    }
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $code';
    }
  }
}
