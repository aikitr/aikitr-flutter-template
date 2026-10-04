import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final class HttpLoggingInterceptor extends Interceptor {
  const HttpLoggingInterceptor(this._logger);

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.fine(() => '${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.fine(
      () =>
          '${response.requestOptions.method} ${response.requestOptions.uri.path} '
          '→ ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warning(
      '${err.requestOptions.method} ${err.requestOptions.uri.path} failed '
      '(${err.response?.statusCode ?? err.type.name})',
    );
    handler.next(err);
  }
}
