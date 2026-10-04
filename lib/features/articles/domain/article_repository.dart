import 'article.dart';

final class ArticlePage {
  const ArticlePage({required this.items, required this.hasMore});

  final List<Article> items;
  final bool hasMore;
}

abstract interface class ArticleRepository {
  Future<ArticlePage> fetchPage({required int page, required int pageSize});

  Future<Article?> findById(String id);
}
