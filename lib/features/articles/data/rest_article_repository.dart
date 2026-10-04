import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/article.dart';
import '../domain/article_repository.dart';

final class RestArticleRepository implements ArticleRepository {
  const RestArticleRepository(this._apiService);

  final ApiService _apiService;

  @override
  Future<ArticlePage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _apiService.get<Map<String, Object?>>(
        '/articles',
        queryParameters: <String, Object?>{'page': page, 'pageSize': pageSize},
      );
      final Map<String, Object?> body = response.data ?? <String, Object?>{};
      final List<Object?> rawItems = body['items']! as List<Object?>;
      return ArticlePage(
        items: rawItems
            .map(
              (Object? value) =>
                  Article.fromJson(value! as Map<String, dynamic>),
            )
            .toList(growable: false),
        hasMore: body['hasMore']! as bool,
      );
    } on RequestCancelledException {
      rethrow;
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AppException(
        AppFailureKind.invalidResponse,
        message: 'The article response did not match the expected schema.',
        cause: error,
      );
    }
  }

  @override
  Future<Article?> findById(String id) async {
    try {
      final response = await _apiService.get<Map<String, Object?>>(
        '/articles/${Uri.encodeComponent(id)}',
      );
      final Map<String, Object?>? body = response.data;
      if (body == null || body.isEmpty) return null;
      return Article.fromJson(body.cast<String, dynamic>());
    } on RequestCancelledException {
      rethrow;
    } on AppException catch (error) {
      final Object? cause = error.cause;
      if (cause is DioException && cause.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } on Object catch (error) {
      throw AppException(
        AppFailureKind.invalidResponse,
        message: 'The article response did not match the expected schema.',
        cause: error,
      );
    }
  }
}
