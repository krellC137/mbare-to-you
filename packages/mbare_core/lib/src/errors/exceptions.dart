/// Base exception class for application-specific exceptions
class AppException implements Exception {
  AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message, [super.code]);
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message, [super.code]);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message, [super.code]);
}

/// Authentication exception
class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException(super.message, [super.code]);
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException(super.message, [super.code]);
}

/// Permission denied exception
class PermissionDeniedException extends AppException {
  PermissionDeniedException(super.message, [super.code]);
}
