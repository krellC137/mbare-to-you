import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/src/errors/failures.dart';

/// Type alias for Either with Failure on the left
typedef Result<T> = Either<Failure, T>;

/// Extension methods for Result type
extension ResultExtension<T> on Result<T> {
  /// Returns the value if Right, otherwise returns the default value
  T getOrElse(T Function() orElse) => fold(
        (_) => orElse(),
        (value) => value,
      );

  /// Returns the value if Right, otherwise null
  T? getOrNull() => fold(
        (_) => null,
        (value) => value,
      );

  /// Returns the failure if Left, otherwise null
  Failure? getFailureOrNull() => fold(
        (failure) => failure,
        (_) => null,
      );

  /// Returns true if this is a Right value
  bool get isSuccess => isRight();

  /// Returns true if this is a Left value
  bool get isFailure => isLeft();
}

/// Helper functions for creating Result instances
Result<T> success<T>(T value) => Right(value);

Result<T> failure<T>(Failure failure) => Left(failure);
