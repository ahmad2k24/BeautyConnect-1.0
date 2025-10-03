// lib/core/app_exceptions.dart
class AppException implements Exception {
  final String message;
  final String? code; // Optional: capture Supabase error code
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() => code != null ? '$code: $message' : message;
}

// ----- Domain-Specific Exceptions -----

/// Thrown when network-related errors occur
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.stackTrace});
}

/// Thrown for authentication-related errors
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.stackTrace});
}

/// Thrown for unexpected/unclassified errors
class UnknownException extends AppException {
  UnknownException(super.message, {super.code, super.stackTrace});
}

/// Thrown when a resource (e.g. user, file, record) is not found
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.stackTrace});
}

/// Thrown when user is not authorized to perform an action
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.stackTrace});
}

/// Thrown when there is a timeout (e.g. request took too long)
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.stackTrace});
}

/// Thrown when there’s a problem with server-side logic or API
class ServerException extends AppException {
  ServerException(super.message, {super.code, super.stackTrace});
}
