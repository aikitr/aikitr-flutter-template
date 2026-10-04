import 'package:app_template/core/errors/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps request timeouts to a user-actionable failure kind', () {
    final AppException failure = AppException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/articles'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(failure.kind, AppFailureKind.timeout);
  });

  test('maps unauthorized and server responses consistently', () {
    final AppException unauthorized = AppException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/private'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/private'),
          statusCode: 401,
        ),
      ),
    );
    final AppException server = AppException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/articles'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/articles'),
          statusCode: 503,
        ),
      ),
    );

    expect(unauthorized.kind, AppFailureKind.unauthorized);
    expect(server.kind, AppFailureKind.server);
  });
}
