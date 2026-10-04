import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../data/local_article_repository.dart';
import '../data/rest_article_repository.dart';
import '../domain/article.dart';
import '../domain/article_feed.dart';
import '../domain/article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  if (config.allowDemoData) return LocalArticleRepository();
  return RestArticleRepository(ref.watch(apiServiceProvider));
});

final articleFeedProvider =
    AsyncNotifierProvider<ArticleFeedController, ArticleFeed>(
      ArticleFeedController.new,
    );

final articleDetailProvider = FutureProvider.family<Article?, String>(
  (Ref ref, String id) => ref.watch(articleRepositoryProvider).findById(id),
);

final class ArticleFeedController extends AsyncNotifier<ArticleFeed> {
  static const int _pageSize = 5;
  int _generation = 0;
  int _nextPage = 1;

  ArticleRepository get _repository => ref.read(articleRepositoryProvider);

  @override
  Future<ArticleFeed> build() async {
    final int generation = ++_generation;
    _nextPage = 1;
    final ArticlePage firstPage = await _repository.fetchPage(
      page: 1,
      pageSize: _pageSize,
    );
    if (generation == _generation) {
      _nextPage = 2;
    }
    return ArticleFeed(items: firstPage.items, hasMore: firstPage.hasMore);
  }

  Future<void> refresh() async {
    final ArticleFeed? previous = state.value;
    final int previousNextPage = _nextPage;
    final int generation = ++_generation;
    _nextPage = 1;
    state = const AsyncLoading<ArticleFeed>();
    try {
      final ArticlePage page = await _repository.fetchPage(
        page: 1,
        pageSize: _pageSize,
      );
      if (generation != _generation) return;
      _nextPage = 2;
      state = AsyncData(ArticleFeed(items: page.items, hasMore: page.hasMore));
    } on Object catch (error, stackTrace) {
      if (generation == _generation) {
        if (error is RequestCancelledException) {
          _nextPage = previousNextPage;
          state = AsyncData(previous ?? const ArticleFeed());
          return;
        }
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> loadNextPage() async {
    final ArticleFeed? current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    final int generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );
    try {
      final ArticlePage page = await _repository.fetchPage(
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (generation != _generation) return;
      final Set<String> existingIds = current.items
          .map((Article item) => item.id)
          .toSet();
      final List<Article> merged = <Article>[
        ...current.items,
        ...page.items.where((Article item) => !existingIds.contains(item.id)),
      ];
      _nextPage++;
      state = AsyncData(ArticleFeed(items: merged, hasMore: page.hasMore));
    } on Object catch (error) {
      if (generation == _generation) {
        if (error is RequestCancelledException) {
          state = AsyncData(current);
          return;
        }
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreError: error),
        );
      }
    }
  }
}
