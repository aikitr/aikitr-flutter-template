import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_template/core/errors/app_exception.dart';
import 'package:app_template/core/network/dio_provider.dart';
import 'package:app_template/core/network/http_logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  test('sends GET requests and keeps secrets out of request logs', () async {
    final Logger rootLogger = Logger.root;
    final Level originalLevel = rootLogger.level;
    rootLogger.level = Level.ALL;
    addTearDown(() => rootLogger.level = originalLevel);
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = _JsonAdapter()
      ..interceptors.add(HttpLoggingInterceptor(Logger('api-service-test')));
    final List<LogRecord> records = <LogRecord>[];
    final StreamSubscription<LogRecord> subscription = rootLogger.onRecord
        .listen(records.add);
    final ApiService api = ApiService(dio);

    final Response<Map<String, Object?>> response = await api.get(
      '/articles',
      queryParameters: <String, Object?>{'token': 'sensitive-query-value'},
    );

    expect(response.data?['ok'], isTrue);
    expect(
      records.map((LogRecord record) => record.message).join('\n'),
      isNot(contains('sensitive-query-value')),
    );
    await subscription.cancel();
    dio.close(force: true);
  });

  test('turns a cancelled request into a silent cancellation signal', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = _JsonAdapter();
    final CancelToken cancelToken = CancelToken()..cancel('screen closed');

    await expectLater(
      ApiService(dio).get<void>('/articles', cancelToken: cancelToken),
      throwsA(isA<RequestCancelledException>()),
    );
    dio.close(force: true);
  });
}

final class _JsonAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(<String, Object?>{'ok': true}),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
