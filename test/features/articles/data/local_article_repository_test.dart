import 'package:app_template/features/articles/data/local_article_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final LocalArticleRepository repository = LocalArticleRepository();

  test('returns stable pages without repeated articles', () async {
    final first = await repository.fetchPage(page: 1, pageSize: 5);
    final second = await repository.fetchPage(page: 2, pageSize: 5);

    expect(first.items, hasLength(5));
    expect(second.items, hasLength(5));
    expect(first.hasMore, isTrue);
    expect(second.hasMore, isTrue);
    expect(
      first.items
          .map((article) => article.id)
          .toSet()
          .intersection(second.items.map((article) => article.id).toSet()),
      isEmpty,
    );
  });

  test('marks the last partial page and missing details correctly', () async {
    final last = await repository.fetchPage(page: 3, pageSize: 5);

    expect(last.items, hasLength(2));
    expect(last.hasMore, isFalse);
    expect(await repository.findById('not-found'), isNull);
  });

  test('rejects non-positive page arguments', () {
    expect(
      () => repository.fetchPage(page: 0, pageSize: 5),
      throwsArgumentError,
    );
    expect(
      () => repository.fetchPage(page: 1, pageSize: 0),
      throwsArgumentError,
    );
  });
}
