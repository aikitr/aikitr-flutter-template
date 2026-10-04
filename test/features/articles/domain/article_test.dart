import 'package:app_template/features/articles/domain/article.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps article JSON round trips immutable and lossless', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'id': 'welcome',
      'title': 'Welcome',
      'summary': 'Template overview',
      'body': 'Feature-first Flutter starter',
      'author': 'Aiki Team',
    };

    final Article article = Article.fromJson(json);

    expect(article.toJson(), json);
    expect(article.copyWith(title: 'Updated').id, 'welcome');
    expect(article.title, 'Welcome');
  });
}
