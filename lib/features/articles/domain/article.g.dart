// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Article _$ArticleFromJson(Map<String, dynamic> json) => _Article(
  id: json['id'] as String,
  title: json['title'] as String,
  summary: json['summary'] as String,
  body: json['body'] as String,
  author: json['author'] as String,
);

Map<String, dynamic> _$ArticleToJson(_Article instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'summary': instance.summary,
  'body': instance.body,
  'author': instance.author,
};
