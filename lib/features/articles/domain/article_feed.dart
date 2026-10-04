import 'package:freezed_annotation/freezed_annotation.dart';

import 'article.dart';

part 'article_feed.freezed.dart';

@freezed
sealed class ArticleFeed with _$ArticleFeed {
  const factory ArticleFeed({
    @Default(<Article>[]) List<Article> items,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    Object? loadMoreError,
  }) = _ArticleFeed;
}
