import 'package:dio/dio.dart';

enum AppFailureKind {
  configuration,
  network,
  timeout,
  unauthorized,
  server,
  invalidResponse,
  storage,
  unknown,
}

final class AppException implements Exception {
  const AppException(this.kind, {this.message, this.cause});

  final AppFailureKind kind;
  final String? message;
  final Object? cause;

  factory AppException.fromDio(DioException error) {
    final AppFailureKind kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => AppFailureKind.timeout,
      DioExceptionType.connectionError => AppFailureKind.network,
      DioExceptionType.cancel => AppFailureKind.network,
      _ => switch (error.response?.statusCode) {
        401 => AppFailureKind.unauthorized,
        final int statusCode when statusCode >= 500 => AppFailureKind.server,
        null => AppFailureKind.network,
        _ => AppFailureKind.invalidResponse,
      },
    };
    return AppException(kind, cause: error);
  }

  @override
  String toString() => message ?? 'AppException($kind)';
}

final class RequestCancelledException implements Exception {
  const RequestCancelledException();
}
