import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ErrorType {
  network,
  authentication,
  permission,
  validation,
  storage,
  unknown,
}

final errorServiceProvider = Provider<ErrorService>((ref) {
  return ErrorServiceImpl();
});

abstract class ErrorService {
  void logError(
    ErrorType type,
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  });

  String getUserFriendlyMessage(ErrorType type, String technicalMessage);
}

class ErrorServiceImpl implements ErrorService {
  @override
  void logError(
    ErrorType type,
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    // For development, print to console
    if (kDebugMode) {
      print('ERROR [${type.name}]: $message');
      if (exception != null) {
        print('Exception: $exception');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // In production, would send to a logging service like Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace);
  }

  @override
  String getUserFriendlyMessage(ErrorType type, String technicalMessage) {
    switch (type) {
      case ErrorType.network:
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Authentication error. Please sign in again.';
      case ErrorType.permission:
        return 'Permission denied. Please enable required permissions in your device settings.';
      case ErrorType.validation:
        return 'Some information is invalid. Please check your input and try again.';
      case ErrorType.storage:
        return 'Error saving data. Please try again.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again later.';
    }
  }
}
