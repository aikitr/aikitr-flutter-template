import 'package:freezed_annotation/freezed_annotation.dart';

part 'article.freezed.dart';
part 'article.g.dart';

@freezed
sealed class Article with _$Article {
  const factory Article({
    required String id,
    required String title,
    required String summary,
    required String body,
    required String author,
  }) = _Article;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
