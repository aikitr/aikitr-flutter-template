import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/app_loading_view.dart';
import '../../../core/ui/app_navigation_bar.dart';
import '../../../core/ui/app_paginated_list.dart';
import '../../../features/articles/application/article_providers.dart';
import '../../../features/articles/domain/article.dart';
import '../../../features/articles/domain/article_feed.dart';

final class ArticleListPage extends ConsumerWidget {
  const ArticleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final feedValue = ref.watch(articleFeedProvider);
    final ArticleFeedController controller = ref.read(
      articleFeedProvider.notifier,
    );
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(
        title: l10n.articlesTitle,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go(AppRoutes.settings),
          child: const Icon(CupertinoIcons.person_crop_circle),
        ),
      ),
      child: feedValue.when(
        loading: () => const AppLoadingView(),
        error: (Object error, StackTrace stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(articleFeedProvider),
        ),
        data: (ArticleFeed feed) => AppPaginatedList<Article>(
          key: const PageStorageKey<String>('article-list'),
          items: feed.items,
          hasMore: feed.hasMore,
          isLoadingMore: feed.isLoadingMore,
          loadMoreError: feed.loadMoreError,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadNextPage,
          itemBuilder: (BuildContext context, Article article, int index) =>
              _ArticleCard(
                article: article,
                onPressed: () =>
                    context.go('${AppRoutes.articles}/${article.id}'),
              ),
        ),
      ),
    );
  }
}

final class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onPressed});

  final Article article;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            article.title,
            style: CupertinoTheme.of(context).textTheme.textStyle
                .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Text(
            article.author,
            style: CupertinoTheme.of(context).textTheme.textStyle
                .copyWith(color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    ),
  );
}
