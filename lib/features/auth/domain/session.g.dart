// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  signedInAt: DateTime.parse(json['signedInAt'] as String),
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'signedInAt': instance.signedInAt.toIso8601String(),
};
