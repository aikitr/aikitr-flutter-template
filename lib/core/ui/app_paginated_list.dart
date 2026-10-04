import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import 'app_empty_view.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';

typedef AppPaginatedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// A Cupertino sliver list with refresh and a reusable pagination footer.
///
/// The owning controller remains responsible for preventing duplicate page
/// requests and de-duplicating results. This widget only renders the state and
/// forwards user actions.
final class AppPaginatedList<T> extends StatelessWidget {
  const AppPaginatedList({
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.loadMoreError,
    this.onRefresh,
    this.emptyView,
    this.padding = const EdgeInsets.fromLTRB(
      AppTheme.pagePadding,
      AppTheme.itemSpacing,
      AppTheme.pagePadding,
      AppTheme.pagePadding,
    ),
    this.separatorBuilder,
    super.key,
  });

  final List<T> items;
  final AppPaginatedItemBuilder<T> itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Object? loadMoreError;
  final Future<void> Function()? onRefresh;
  final Widget? emptyView;
  final EdgeInsetsGeometry padding;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: key,
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: <Widget>[
      if (onRefresh case final Future<void> Function() refresh)
        CupertinoSliverRefreshControl(onRefresh: refresh),
      if (items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: emptyView ?? const AppEmptyView(),
        )
      else ...<Widget>[
        SliverPadding(
          padding: padding,
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder:
                separatorBuilder ??
                (BuildContext context, int index) =>
                    const SizedBox(height: AppTheme.itemSpacing),
            itemBuilder: (BuildContext context, int index) =>
                itemBuilder(context, items[index], index),
          ),
        ),
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: _PaginationFooter(
                isLoading: isLoadingMore,
                error: loadMoreError,
                onRetry: onLoadMore,
              ),
            ),
          ),
      ],
    ],
  );
}

final class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const AppLoadingView();
    if (error case final Object loadError) {
      return AppErrorView(error: loadError, onRetry: onRetry);
    }
    return CupertinoButton(
      onPressed: onRetry,
      child: Text(AppLocalizations.of(context).loadMore),
    );
  }
}
