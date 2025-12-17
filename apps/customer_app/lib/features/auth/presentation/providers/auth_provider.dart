import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Auth state notifier for managing authentication actions
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserModel?> build() async {
    // Watch current user from repository
    return ref.watch(currentUserProvider).value;
  }

  /// Sign in with email and password
  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.signIn(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (user) => state = AsyncData(user),
    );

    return result;
  }

  /// Register new user
  Future<Result<UserModel>> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.register(
      email: email,
      password: password,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: 'customer', // Default role for customer app
    );

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (user) => state = AsyncData(user),
    );

    return result;
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.signOut();

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) => state = const AsyncData(null),
    );

    return result;
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.sendPasswordResetEmail(email);
  }
}
