import 'dart:async';

import 'package:app_template/core/errors/app_exception.dart';
import 'package:app_template/features/articles/application/article_providers.dart';
import 'package:app_template/features/articles/domain/article.dart';
import 'package:app_template/features/articles/domain/article_feed.dart';
import 'package:app_template/features/articles/domain/article_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'merges pages by ID and stops when the repository reaches the end',
    () async {
      final _StubArticleRepository repository = _StubArticleRepository(
        <int, ArticlePage>{
          1: ArticlePage(
            items: <Article>[_article('a'), _article('b')],
            hasMore: true,
          ),
          2: ArticlePage(
            items: <Article>[_article('b'), _article('c')],
            hasMore: false,
          ),
        },
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [articleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final ArticleFeed initial = await container.read(
        articleFeedProvider.future,
      );
      await container.read(articleFeedProvider.notifier).loadNextPage();
      await container.read(articleFeedProvider.notifier).loadNextPage();
      final ArticleFeed result = container
          .read(articleFeedProvider)
          .requireValue;

      expect(initial.items, hasLength(2));
      expect(result.items.map((Article item) => item.id), <String>[
        'a',
        'b',
        'c',
      ]);
      expect(result.hasMore, isFalse);
      expect(repository.pageCalls, <int>[1, 2]);
    },
  );

  test('does not issue duplicate concurrent next-page requests', () async {
    final Completer<ArticlePage> pageGate = Completer<ArticlePage>();
    final _StubArticleRepository repository = _StubArticleRepository(
      <int, ArticlePage>{
        1: ArticlePage(items: <Article>[_article('a')], hasMore: true),
      },
      gatedPage: 2,
      gate: pageGate,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [articleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(articleFeedProvider.future);

    final ArticleFeedController controller = container.read(
      articleFeedProvider.notifier,
    );
    final Future<void> first = controller.loadNextPage();
    final Future<void> duplicate = controller.loadNextPage();
    pageGate.complete(
      ArticlePage(items: <Article>[_article('b')], hasMore: false),
    );
    await Future.wait(<Future<void>>[first, duplicate]);

    expect(repository.pageCalls, <int>[1, 2]);
    expect(
      container.read(articleFeedProvider).requireValue.items,
      hasLength(2),
    );
  });

  test(
    'keeps visible items after a pagination error so the user can retry',
    () async {
      final _StubArticleRepository repository = _StubArticleRepository(
        <int, ArticlePage>{
          1: ArticlePage(items: <Article>[_article('a')], hasMore: true),
        },
      )..failPage = 2;
      final ProviderContainer container = ProviderContainer(
        overrides: [articleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(articleFeedProvider.future);

      await container.read(articleFeedProvider.notifier).loadNextPage();
      final ArticleFeed result = container
          .read(articleFeedProvider)
          .requireValue;

      expect(result.items, hasLength(1));
      expect(result.isLoadingMore, isFalse);
      expect(result.hasMore, isTrue);
      expect(result.loadMoreError, isA<StateError>());
    },
  );

  test('does not surface a cancelled page as a pagination error', () async {
    final _StubArticleRepository repository =
        _StubArticleRepository(<int, ArticlePage>{
            1: ArticlePage(items: <Article>[_article('a')], hasMore: true),
          })
          ..failPage = 2
          ..failPageError = const RequestCancelledException();
    final ProviderContainer container = ProviderContainer(
      overrides: [articleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(articleFeedProvider.future);

    await container.read(articleFeedProvider.notifier).loadNextPage();
    final ArticleFeed result = container.read(articleFeedProvider).requireValue;

    expect(result.items, hasLength(1));
    expect(result.isLoadingMore, isFalse);
    expect(result.loadMoreError, isNull);
  });

  test('keeps the current feed when refresh is cancelled', () async {
    final _StubArticleRepository repository = _StubArticleRepository(
      <int, ArticlePage>{
        1: ArticlePage(items: <Article>[_article('a')], hasMore: true),
      },
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [articleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(articleFeedProvider.future);
    repository.failPage = 1;
    repository.failPageError = const RequestCancelledException();

    await container.read(articleFeedProvider.notifier).refresh();
    final ArticleFeed result = container.read(articleFeedProvider).requireValue;

    expect(result.items.map((Article item) => item.id), <String>['a']);
    expect(result.loadMoreError, isNull);
  });

  test(
    'a refresh ignores any older page request that completes later',
    () async {
      final Completer<ArticlePage> oldPage = Completer<ArticlePage>();
      final _StubArticleRepository repository = _StubArticleRepository(
        <int, ArticlePage>{
          1: ArticlePage(items: <Article>[_article('old')], hasMore: true),
        },
        gatedPage: 2,
        gate: oldPage,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [articleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(articleFeedProvider.future);

      final Future<void> pendingPage = container
          .read(articleFeedProvider.notifier)
          .loadNextPage();
      repository.pages[1] = ArticlePage(
        items: <Article>[_article('fresh')],
        hasMore: false,
      );
      await container.read(articleFeedProvider.notifier).refresh();
      oldPage.complete(
        ArticlePage(items: <Article>[_article('stale')], hasMore: false),
      );
      await pendingPage;

      expect(
        container
            .read(articleFeedProvider)
            .requireValue
            .items
            .map((Article item) => item.id),
        <String>['fresh'],
      );
    },
  );
}

Article _article(String id) =>
    Article(id: id, title: id, summary: id, body: id, author: id);

final class _StubArticleRepository implements ArticleRepository {
  _StubArticleRepository(this.pages, {this.gatedPage, this.gate});

  final Map<int, ArticlePage> pages;
  final int? gatedPage;
  final Completer<ArticlePage>? gate;
  final List<int> pageCalls = <int>[];
  int? failPage;
  Object? failPageError;

  @override
  Future<ArticlePage> fetchPage({required int page, required int pageSize}) {
    pageCalls.add(page);
    if (page == failPage) {
      return Future<ArticlePage>.error(failPageError ?? StateError('offline'));
    }
    if (page == gatedPage && gate != null) return gate!.future;
    return Future<ArticlePage>.value(
      pages[page] ?? const ArticlePage(items: <Article>[], hasMore: false),
    );
  }

  @override
  Future<Article?> findById(String id) async {
    for (final ArticlePage page in pages.values) {
      for (final Article article in page.items) {
        if (article.id == id) return article;
      }
    }
    return null;
  }
}
