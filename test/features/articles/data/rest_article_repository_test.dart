import 'dart:convert';
import 'dart:typed_data';

import 'package:app_template/core/errors/app_exception.dart';
import 'package:app_template/core/network/dio_provider.dart';
import 'package:app_template/features/articles/data/rest_article_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a missing detail response to null', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = const _JsonAdapter(
        <String, Object?>{},
        statusCode: 404,
      );
    addTearDown(dio.close);
    final RestArticleRepository repository = RestArticleRepository(
      ApiService(dio),
    );

    expect(await repository.findById('missing'), isNull);
  });

  test('maps malformed detail JSON to an application response error', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = _JsonAdapter(<String, Object?>{'id': 42});
    addTearDown(dio.close);
    final RestArticleRepository repository = RestArticleRepository(
      ApiService(dio),
    );

    await expectLater(
      repository.findById('story'),
      throwsA(
        isA<AppException>().having(
          (AppException error) => error.kind,
          'kind',
          AppFailureKind.invalidResponse,
        ),
      ),
    );
  });
}

final class _JsonAdapter implements HttpClientAdapter {
  const _JsonAdapter(this._body, {this.statusCode = 200});

  final Map<String, Object?> _body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(_body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
