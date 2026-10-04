import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/app_config.dart';
import '../../features/auth/application/session_controller.dart';
import '../errors/app_exception.dart';
import 'http_logging_interceptor.dart';

final loggerProvider = Provider<Logger>((Ref ref) => Logger('app'));

final dioProvider = Provider<Dio>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  if (config.apiBaseUrl.isEmpty) {
    throw const AppException(
      AppFailureKind.configuration,
      message: 'Set API_BASE_URL to use network repositories.',
    );
  }
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: <String, String>{'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(HttpLoggingInterceptor(ref.watch(loggerProvider)));
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse:
          (Response<Object?> response, ResponseInterceptorHandler handler) {
            if (response.statusCode == 401) {
              ref.read(authSessionInvalidatedProvider.notifier).signal();
            }
            handler.next(response);
          },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        if (error.response?.statusCode == 401) {
          ref.read(authSessionInvalidatedProvider.notifier).signal();
        }
        handler.next(error);
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final class ApiService {
  const ApiService(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) => _execute<T>(
    () => _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) => _execute<T>(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    ),
  );

  Future<Response<T>> _execute<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const RequestCancelledException();
      throw AppException.fromDio(error);
    }
  }
}

final apiServiceProvider = Provider<ApiService>(
  (Ref ref) => ApiService(ref.watch(dioProvider)),
);
