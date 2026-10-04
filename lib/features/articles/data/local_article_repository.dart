import '../domain/article.dart';
import '../domain/article_repository.dart';

final class LocalArticleRepository implements ArticleRepository {
  LocalArticleRepository([List<Article>? articles])
    : _articles = List<Article>.unmodifiable(articles ?? _demoArticles);

  final List<Article> _articles;

  @override
  Future<ArticlePage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    if (page < 1 || pageSize < 1) {
      throw ArgumentError('Page and page size must be positive.');
    }
    final int start = (page - 1) * pageSize;
    if (start >= _articles.length) {
      return const ArticlePage(items: <Article>[], hasMore: false);
    }
    final int end = (start + pageSize).clamp(0, _articles.length);
    return ArticlePage(
      items: _articles.sublist(start, end),
      hasMore: end < _articles.length,
    );
  }

  @override
  Future<Article?> findById(String id) async {
    for (final Article article in _articles) {
      if (article.id == id) return article;
    }
    return null;
  }
}

final List<Article> _demoArticles = List<Article>.generate(
  12,
  (int index) => Article(
    id: 'article-${index + 1}',
    title: 'Building a thoughtful iOS app ${index + 1}',
    summary: 'A practical note on keeping application code clear and testable.',
    body:
        'Start with a feature the user can see. Keep its state and data access '
        'close to the feature, and share only the pieces that serve the whole '
        'application. Add a new layer when real business rules need it.',
    author: index.isEven ? 'Aiki Team' : 'Flutter Community',
  ),
);
